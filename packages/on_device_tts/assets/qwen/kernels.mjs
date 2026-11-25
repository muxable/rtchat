// One autoregressive sequence per dispatch. Weights, activations and KV stay
// on the device. A 4-bit block is four u32 words, a scale and a zero point.
const buffer = (slot, name, type, write = false) =>
  `@group(0) @binding(${slot}) var<storage,${write ? "read_write" : "read"}> ${name}:array<${type}>;\n`;

const unpack = `
fn weight(bits:u32, lane:u32, scale:f32, zero:f32) -> f32 {
  return (f32((bits >> (4u * lane)) & 15u) - zero) * scale;
}`;

const reduction = `
var<workgroup> sums:array<f32,64>;
fn sum64(value:f32,lane:u32) -> f32 {
  sums[lane]=value; workgroupBarrier();
  for(var span=32u; span>0u; span=span>>1u) {
    if(lane<span) { sums[lane]+=sums[lane+span]; }
    workgroupBarrier();
  }
  return sums[0];
}`;

export function q4Product(columns, subgroups = false) {
  if (subgroups) {
    return `enable subgroups;
@group(0) @binding(0) var<storage,read> x:array<vec4f>;
@group(0) @binding(1) var<storage,read> w:array<u32>;
@group(0) @binding(2) var<storage,read_write> y:array<f32>;
var<workgroup> partial:array<f32,32>;
@compute @workgroup_size(32) fn main(@builtin(workgroup_id) group:vec3u,
 @builtin(local_invocation_index) lane:u32,@builtin(subgroup_size) width:u32){
 var acc=0.0;let row=group.x*${(columns / 32) * 6}u;
 for(var j=lane;j<${columns / 8}u;j+=32u){
   let base=row+(j/4u)*6u;
   let word=w[base+j%4u];let scale=bitcast<f32>(w[base+4u]);let zero=vec4f(f32(w[base+5u]));
   let shift=vec4u(0u,4u,8u,12u);
   let lo=(vec4f((vec4u(word)>>shift)&vec4u(15u))-zero)*scale;
   let hi=(vec4f((vec4u(word>>16u)>>shift)&vec4u(15u))-zero)*scale;
   acc+=dot(x[j*2u],lo)+dot(x[j*2u+1u],hi);
 }
 let sum=subgroupAdd(acc);
 if(width>=32u){if(lane==0u){y[group.x]=sum;}}
 else {
   partial[lane]=select(0.0,sum,subgroupElect());workgroupBarrier();
   if(lane==0u){var total=0.0;for(var i=0u;i<32u;i++){total+=partial[i];}y[group.x]=total;}
 }
}`;
  }
  return (
    buffer(0, "x", "f32") +
    buffer(1, "w", "u32") +
    buffer(2, "y", "f32", true) +
    unpack +
    reduction +
    `
@compute @workgroup_size(64)
fn main(@builtin(workgroup_id) group:vec3u,@builtin(local_invocation_index) lane:u32) {
  let blocks=${columns / 32}u;
  var acc=0.0;
  for(var block=lane;block<blocks;block+=64u) {
    let base=(group.x*blocks+block)*6u;
    let scale=bitcast<f32>(w[base+4u]); let zero=f32(w[base+5u]);
    for(var j=0u;j<4u;j++) {
      let bits=w[base+j];
      for(var k=0u;k<8u;k++) { acc+=x[block*32u+j*8u+k]*weight(bits,k,scale,zero); }
    }
  }
  let value=sum64(acc,lane);
  if(lane==0u){y[group.x]=value;}
}`
  );
}

export const embed =
  buffer(0, "codes", "u32") +
  buffer(1, "step", "u32") +
  buffer(2, "w", "u32") +
  buffer(3, "x", "f32", true) +
  unpack +
  `
@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id:vec3u) {
  let col=id.x; let row=codes[step[0]-1u];
  let base=(row*32u+col/32u)*6u;
  x[col]=weight(w[base+(col%32u)/8u],col%8u,bitcast<f32>(w[base+4u]),f32(w[base+5u]));
}`;

export const norm =
  buffer(0, "x", "f32") +
  buffer(1, "w", "f32") +
  buffer(2, "y", "f32", true) +
  reduction +
  `
@compute @workgroup_size(64)
fn main(@builtin(local_invocation_index) lane:u32) {
  var acc=0.0; for(var i=lane;i<1024u;i+=64u){acc+=x[i]*x[i];}
  let inv=inverseSqrt(sum64(acc,lane)/1024.0+0.000001);
  for(var i=lane;i<1024u;i+=64u){y[i]=x[i]*inv*w[i];}
}`;

export const cache =
  buffer(0, "qkv", "f32") +
  buffer(1, "qn", "f32") +
  buffer(2, "kn", "f32") +
  buffer(3, "step", "u32") +
  buffer(4, "q", "f32", true) +
  buffer(5, "keys", "f32", true) +
  buffer(6, "vals", "f32", true) +
  reduction +
  `
@compute @workgroup_size(64)
fn main(@builtin(workgroup_id) group:vec3u,@builtin(local_invocation_index) i:u32) {
  let h=group.x; let pos=step[0]; let offset=h*128u;
  let a=qkv[offset+i]; let b=qkv[offset+64u+i];
  let inv=inverseSqrt(sum64(a*a+b*b,i)/128.0+0.000001);
  let angle=f32(pos)*pow(1000000.0,-f32(i)/64.0);
  let c=cos(angle); let s=sin(angle);
  if(h<16u) {
    let x=a*inv*qn[i]; let y=b*inv*qn[64u+i];
    q[offset+i]=x*c-y*s; q[offset+64u+i]=y*c+x*s;
  } else {
    let keyOffset=pos*1024u+(h-16u)*128u;
    let x=a*inv*kn[i]; let y=b*inv*kn[64u+i];
    keys[keyOffset+i]=x*c-y*s; keys[keyOffset+64u+i]=y*c+x*s;
    vals[keyOffset+i]=qkv[offset+1024u+i];
    vals[keyOffset+64u+i]=qkv[offset+1088u+i];
  }
}`;

export const attention = (capacity) =>
  buffer(0, "q", "f32") +
  buffer(1, "keys", "f32") +
  buffer(2, "vals", "f32") +
  buffer(3, "step", "u32") +
  buffer(4, "outv", "f32", true) +
  `
var<workgroup> scores:array<f32,${capacity}>;
@compute @workgroup_size(128)
fn main(@builtin(workgroup_id) group:vec3u,@builtin(local_invocation_index) lane:u32) {
  let pos=step[0]; let h=group.x; let offset=(h/2u)*128u;
  for(var token=lane;token<=pos;token+=128u) {
    var dot=0.0; for(var i=0u;i<128u;i++){dot+=q[h*128u+i]*keys[token*1024u+offset+i];}
    scores[token]=dot*inverseSqrt(128.0);
  }
  workgroupBarrier();
  if(lane==0u) {
    var mx=scores[0]; for(var i=1u;i<=pos;i++){mx=max(mx,scores[i]);}
    var den=0.0; for(var i=0u;i<=pos;i++){scores[i]=exp(scores[i]-mx);den+=scores[i];}
    for(var i=0u;i<=pos;i++){scores[i]/=den;}
  }
  workgroupBarrier();
  var v=0.0;for(var i=0u;i<=pos;i++){v+=scores[i]*vals[i*1024u+offset+lane];}
  outv[h*128u+lane]=v;
}`;

export const add =
  buffer(0, "x", "f32", true) +
  buffer(1, "y", "f32") +
  `
@compute @workgroup_size(64) fn main(@builtin(global_invocation_id) id:vec3u){x[id.x]+=y[id.x];}`;
export const silu =
  buffer(0, "pair", "f32") +
  buffer(1, "y", "f32", true) +
  `
@compute @workgroup_size(64) fn main(@builtin(global_invocation_id) id:vec3u){
 let gate=pair[id.x]; y[id.x]=(gate/(1.0+exp(-gate)))*pair[id.x+3072u];
}`;
export const argmax =
  buffer(0, "logits", "f32") +
  buffer(1, "codes", "u32", true) +
  buffer(2, "step", "u32") +
  `
var<workgroup> best:array<f32,64>;var<workgroup> ids:array<u32,64>;
@compute @workgroup_size(64) fn main(@builtin(local_invocation_index) lane:u32){
 var token=lane; var score=logits[lane];
 for(var i=lane+64u;i<2048u;i+=64u){if(logits[i]>score){token=i;score=logits[i];}}
 ids[lane]=token;best[lane]=score;workgroupBarrier();
 for(var span=32u;span>0u;span=span>>1u){
  if(lane<span){
   let rhs=lane+span;
   if(best[rhs]>best[lane] || (best[rhs]==best[lane] && ids[rhs]<ids[lane])){
    best[lane]=best[rhs];ids[lane]=ids[rhs];
   }
  }
  workgroupBarrier();
 }
 if(lane==0u){codes[step[0]]=ids[0];}
}`;
