import Foundation

enum GraphElement {
  case float32, int64
}

struct GraphTensor {
  let data: Data
  let shape: [Int]
  let element: GraphElement
}

protocol GraphSession {
  func run(_ inputs: [String: GraphTensor], output: String) throws -> GraphTensor
}

typealias OpenGraph = (URL) throws -> GraphSession

func floatTensor(_ values: [Float], shape: [Int]) throws -> GraphTensor {
  try tensor(values, shape: shape, element: .float32)
}

func int64Tensor(_ values: [Int64], shape: [Int]) throws -> GraphTensor {
  try tensor(values, shape: shape, element: .int64)
}

private func tensor<T>(_ values: [T], shape: [Int], element: GraphElement) throws -> GraphTensor {
  guard shape.reduce(1, *) == values.count else { throw SupertonicError.invalidModel("Invalid tensor shape") }
  return GraphTensor(data: values.withUnsafeBytes { Data($0) }, shape: shape, element: element)
}

func floats(_ value: GraphTensor) throws -> [Float] {
  guard value.element == .float32 && value.data.count % 4 == 0 else {
    throw SupertonicError.inference("Expected FLOAT tensor")
  }
  var result = [Float](repeating: 0, count: value.data.count / 4)
  _ = result.withUnsafeMutableBytes { value.data.copyBytes(to: $0) }
  return result
}
