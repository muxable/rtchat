import Foundation

/// The Gaussian noise that flow matching starts from, made by a small PRNG
/// that every platform implements the same way, so a seed gives the same
/// noise (and nearly the same audio) on iOS and Android. See "Noise PRNG" in
/// `doc/native_contract.md`:
///
/// * SplitMix64 makes 64-bit words: `state += 0x9E3779B97F4A7C15`, then
///   `z = state; z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9;
///   z = (z ^ (z >> 27)) * 0x94D049BB133111EB; return z ^ (z >> 31)`, all
///   modulo 2^64. The initial state is the seed's two's-complement bits.
/// * A uniform double in [0, 1) is `(word >> 11) * 2^-53`.
/// * Each normal sample takes two uniforms, `u1` then `u2`, and is
///   `sqrt(-2 * ln(1 - u1)) * cos(2 * pi * u2)` in double precision, then
///   rounded to float.
/// * Tensors are filled in row-major order.
public struct NoiseGenerator {
  private var state: UInt64

  public init(seed: Int64) {
    state = UInt64(bitPattern: seed)
  }

  /// A generator with a random seed, for when the caller doesn't ask for
  /// deterministic output.
  public static func random() -> NoiseGenerator {
    NoiseGenerator(seed: Int64.random(in: Int64.min...Int64.max))
  }

  public mutating func nextUInt64() -> UInt64 {
    state = state &+ 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }

  public mutating func nextDouble() -> Double {
    Double(nextUInt64() >> 11) * (1.0 / 9_007_199_254_740_992.0)
  }

  public mutating func nextGaussian() -> Float {
    let u1 = nextDouble()
    let u2 = nextDouble()
    return Float((-2.0 * log(1.0 - u1)).squareRoot() * cos(2.0 * Double.pi * u2))
  }

  /// `count` standard normal samples, in order.
  public mutating func gaussians(_ count: Int) -> [Float] {
    var values = [Float](repeating: 0, count: count)
    for i in 0..<count {
      values[i] = nextGaussian()
    }
    return values
  }
}
