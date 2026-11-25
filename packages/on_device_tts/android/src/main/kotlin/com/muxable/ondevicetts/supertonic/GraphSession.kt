package com.muxable.ondevicetts.supertonic

import java.io.Closeable

internal class GraphTensor(val data: Any, val shape: LongArray) {
    val floats get() = data as FloatArray
}

internal interface GraphSession : Closeable {
    fun run(inputs: Map<String, GraphTensor>): GraphTensor
}
