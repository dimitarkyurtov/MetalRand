//
//  MetalRandomNumberGenerator.swift
//  MetalRandExample
//
//  Created by Dimitar Kyurtov on 4.05.25.
//

import Metal
import Foundation

class MetalRandomNumberGenerator {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let setupPipeline: MTLComputePipelineState
    private let generatePipeline: MTLComputePipelineState
    
    private let stateBuffer: MTLBuffer
    private let seedBuffer: MTLBuffer
    private let outputBuffer: MTLBuffer
    private let countBuffer: MTLBuffer
    
    private let threadCount = 10
    private let numbersPerThread = 10

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let setupFunction = library.makeFunction(name: "setup_kernel"),
              let generateFunction = library.makeFunction(name: "generate_random_numbers") else {
            print("Failed to initialize Metal.")
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue

        do {
            setupPipeline = try device.makeComputePipelineState(function: setupFunction)
            generatePipeline = try device.makeComputePipelineState(function: generateFunction)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }

        let stateSize = MemoryLayout<UInt32>.stride * 6 // XORWOWState has 6 uints
        stateBuffer = device.makeBuffer(length: stateSize * threadCount, options: [])!
        outputBuffer = device.makeBuffer(length: threadCount * numbersPerThread * MemoryLayout<Float>.stride, options: [])!

        var count = UInt32(numbersPerThread)
        countBuffer = device.makeBuffer(bytes: &count, length: MemoryLayout<UInt32>.stride, options: [])!
        
        var seed = UInt32(12345)
        seedBuffer = device.makeBuffer(bytes: &seed, length: MemoryLayout<UInt32>.stride, options: [])!

        runSetupKernel()
    }

    private func runSetupKernel() {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }

        encoder.setComputePipelineState(setupPipeline)
        encoder.setBuffer(stateBuffer, offset: 0, index: 0)
        encoder.setBuffer(seedBuffer, offset: 0, index: 1)

        let threadsPerGrid = MTLSize(width: threadCount, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    func generateRandomNumbers() {
        for iteration in 0..<10 {
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let encoder = commandBuffer.makeComputeCommandEncoder() else { return }

            encoder.setComputePipelineState(generatePipeline)
            encoder.setBuffer(stateBuffer, offset: 0, index: 0)
            encoder.setBuffer(outputBuffer, offset: 0, index: 1)
            encoder.setBuffer(countBuffer, offset: 0, index: 2)

            let threadsPerGrid = MTLSize(width: threadCount, height: 1, depth: 1)
            let threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)

            encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            encoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            let outputPointer = outputBuffer.contents().bindMemory(to: Float.self, capacity: threadCount * numbersPerThread)
            print("Iteration \(iteration + 1):")
            for thread in 0..<threadCount {
                let startIndex = thread * numbersPerThread
                let values = (0..<numbersPerThread).map { outputPointer[startIndex + $0] }
                print("Thread \(thread): \(values)")
            }
            print()
        }
    }
}
