#!/usr/bin/env bash
# Fetch the original files pinned by the bundled voice-pack catalog.
set -euo pipefail
version=$1
dir=$2
case "$version" in
  2) revision=75e6727618a02f323c720cba9478152d4bc16ca4 ;;
  3) revision=3cadd1ee6394adea1bd021217a0e650ede09a323 ;;
  *) exit 2 ;;
esac
mkdir -p "$dir/onnx" "$dir/voice_styles"
manifest() {
  if [[ "$version" == 2 ]]; then
    cat <<'EOF'
6d556b3691165c364be91dc0bd894656b5949f5acd2750d8ec2f954010845011  onnx/duration_predictor.onnx
dd5f535ed629f7df86071043e15f541ce1b2ab7f1bdbce4c7892b307bca79fa3  onnx/text_encoder.onnx
ee531d9af9b80438a2ed703e22155ee6c83b12595ab22fd3bb6de94c7502fe96  onnx/tts.json
b7662a73a0703f43b97c0f2e089f8e8325e26f5d841aca393b5a54c509c92df1  onnx/unicode_indexer.json
105e9d66fd8756876b210a6b4aa03fc393b1eaca3a8dadcc8d9a3bc785c86a35  onnx/vector_estimator.onnx
19bd51f47a186069c752403518a40f7ea4c647455056d2511f7249691ecddf7c  onnx/vocoder.onnx
6106950ebeb8a5da29ea22075f605db659cd07dbc288a68292543d9129aa250f  voice_styles/F1.json
8b97feb16d79ac0447136796708feac5f83dbabe92a5be1168212653c38729ae  voice_styles/F2.json
7eda5bccb4e6eb7f228fa182462d5fcf982d77628234603599027f0734d70c29  voice_styles/F3.json
e056fc2bee393edc8bff761eb28f33fb461e8dad828c3b05348a010ac1b7bb79  voice_styles/F4.json
ce7645ad7e3c13cca04e0d62bf890ef9ac401988005ba8f5e9c9b59257bc6931  voice_styles/F5.json
a04c823cbda6dd1c7de131ec68fea83bbb70d7f29d61623304eb871e3b83b5a1  voice_styles/M1.json
7ddd07bf873a3fd67d09ef4e8293b486beb658158b47e371166198e4c6926072  voice_styles/M2.json
e8e77a56459e4dc8cdfeb88e6f778dc9a0adf22e1184414f4b0e82a5d1edbe72  voice_styles/M3.json
95322725e4d25d9ed4e7dcccbf0f3726b0e9a2471d876b7942373218dbd30174  voice_styles/M4.json
be52f82327da63ff18481ce2dd8060c7df432e0168d748745ef3e21b92d706a5  voice_styles/M5.json
EOF
  else
    cat <<'EOF'
c3eb91414d5ff8a7a239b7fe9e34e7e2bf8a8140d8375ffb14718b1c639325db  onnx/duration_predictor.onnx
c7befd5ea8c3119769e8a6c1486c4edc6a3bc8365c67621c881bbb774b9902ff  onnx/text_encoder.onnx
42078d3aef1cd43ab43021f3c54f47d2d75ceb4e75f627f118890128b06a0d09  onnx/tts.json
9bf7346e43883a81f8645c81224f786d43c5b57f3641f6e7671a7d6c493cb24f  onnx/unicode_indexer.json
883ac868ea0275ef0e991524dc64f16b3c0376efd7c320af6b53f5b780d7c61c  onnx/vector_estimator.onnx
085de76dd8e8d5836d6ca66826601f615939218f90e519f70ee8a36ed2a4c4ba  onnx/vocoder.onnx
bbdec6ee00231c2c742ad05483df5334cab3b52fda3ba38e6a07059c4563dbc2  voice_styles/F1.json
7c722c6a72707b1a77f035d67f0d1351ba187738e06f7683e8c72b1df3477fc6  voice_styles/F2.json
12f6ef2573baa2defa1128069cb59f203e3ab67c92af77b42df8a0e3a2f7c6ab  voice_styles/F3.json
c2fa764c1225a76dfc3e2c73e8aa4f70d9ee48793860eb34c295fff01c2e032b  voice_styles/F4.json
45966e73316415626cf41a7d1c6f3b4c70dbc1ba2bee5c1978ef0ce33244fc8d  voice_styles/F5.json
e35604687f5d23694b8e91593a93eec0e4eca6c0b02bb8ed69139ab2ea6b0a5b  voice_styles/M1.json
b76cbf62bac707c710cf0ae5aba5e31eea1a6339a9734bfae33ab98499534a50  voice_styles/M2.json
ea1ac35ccb91b0d7ecad533a2fbd0eec10c91513d8951e3b25fbba99954e159b  voice_styles/M3.json
ca8eefad4fcd989c9379032ff3e50738adc547eeb5e221b82593a6d7b3bac303  voice_styles/M4.json
dd22b92740314321f8ae11c5e87f8dd60d060f15dd3a632b5adf77f471f77af2  voice_styles/M5.json
EOF
  fi
}
while read -r sha file; do
  if [[ -f "$dir/$file" ]] && echo "$sha  $dir/$file" | shasum -a 256 -c - >/dev/null; then continue; fi
  curl -fsSL --retry 3 "https://huggingface.co/Supertone/supertonic-$version/resolve/$revision/$file" -o "$dir/$file"
  echo "$sha  $dir/$file" | shasum -a 256 -c -
done < <(manifest)
