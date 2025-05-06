//
//  MetalRandomView.swift
//  MetalRandExample
//
//  Created by Dimitar Kyurtov on 5.05.25.
//

import Foundation
import SwiftUI
import MetalKit

struct MetalRandomView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()!
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.device
        view.clearColor = MTLClearColorMake(0, 0, 0, 1)
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm
        view.delegate = context.coordinator
        context.coordinator.setup(view: view)
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}

class Coordinator: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let setupPipeline: MTLComputePipelineState
    let renderPipeline: MTLRenderPipelineState

    let stateBuffer: MTLBuffer
    let seedBuffer: MTLBuffer

    let width = 512
    let height = 512

    init?(_ device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        guard let device = device,
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let setupFunction = library.makeFunction(name: "setup_kernel"),
              let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main")
        else { return nil }

        self.device = device
        self.commandQueue = commandQueue

        do {
            setupPipeline = try device.makeComputePipelineState(function: setupFunction)
        } catch {
            print("Setup pipeline error: \(error)")
            return nil
        }

        let renderDesc = MTLRenderPipelineDescriptor()
        renderDesc.vertexFunction = vertexFunction
        renderDesc.fragmentFunction = fragmentFunction
        renderDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            renderPipeline = try device.makeRenderPipelineState(descriptor: renderDesc)
        } catch {
            print("Render pipeline error: \(error)")
            return nil
        }

        let stateSize = MemoryLayout<UInt32>.stride * 6
        stateBuffer = device.makeBuffer(length: width * height * stateSize, options: .storageModeShared)!

        var seed: UInt32 = 12345
        seedBuffer = device.makeBuffer(bytes: &seed, length: MemoryLayout<UInt32>.stride, options: [])!

        super.init()
    }

    func setup(view: MTKView) {
        view.drawableSize = CGSize(width: width, height: height)
        runSetup()
    }
    
    private func runSetup() {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }

        encoder.setComputePipelineState(setupPipeline)
        encoder.setBuffer(stateBuffer, offset: 0, index: 0)
        encoder.setBuffer(seedBuffer, offset: 0, index: 1)

        let totalThreads = width * height
        let threadsPerGrid = MTLSize(width: totalThreads, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: min(setupPipeline.threadExecutionWidth, totalThreads), height: 1, depth: 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        var viewportSize = vector_uint2(UInt32(width), UInt32(height))
        var widthValue = UInt32(width)

        encoder.setRenderPipelineState(renderPipeline)
        encoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 0)
        encoder.setFragmentBuffer(stateBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(&widthValue, length: MemoryLayout<UInt32>.stride, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
