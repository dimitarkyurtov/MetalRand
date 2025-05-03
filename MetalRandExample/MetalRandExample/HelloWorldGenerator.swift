//
//  HelloWorldGenerator.swift
//  MetalRandExample
//
//  Created by Dimitar Kyurtov on 3.05.25.
//

import Foundation
import Metal

public class HelloWorldGenerator {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLComputePipelineState

    public init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let metallibPath = Bundle.main.path(forResource: "MetalRand", ofType: "metallib"),
              let library = try? device.makeLibrary(filepath: metallibPath),
              let function = library.makeFunction(name: "hello_world"),
              let pipeline = try? device.makeComputePipelineState(function: function)
        else {
            return nil
        }
        
        self.device = device
        self.commandQueue = queue
        self.pipeline = pipeline
    }

    public func generateHelloWorld() -> String? {
        let bufferLength = 64
        guard let buffer = device.makeBuffer(length: bufferLength, options: .storageModeShared),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return nil
        }

        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(buffer, offset: 0, index: 0)

        let threadCount = MTLSize(width: bufferLength, height: 1, depth: 1)
        let threadGroupSize = MTLSize(width: 1, height: 1, depth: 1)

        encoder.dispatchThreads(threadCount, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let outputPointer = buffer.contents().assumingMemoryBound(to: CChar.self)
        return String(cString: outputPointer)
    }
}
