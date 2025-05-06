//
//  MetalRandomView.swift
//  MetalRandExample
//
//  Created by Dimitar Kyurtov on 5.05.25.
//

import Foundation
import SwiftUI
import MetalKit

import SwiftUI
import MetalKit

struct MetalRandomView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()!
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = context.coordinator.device
        mtkView.framebufferOnly = false
        mtkView.delegate = context.coordinator
        context.coordinator.setup(view: mtkView)
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}

class Coordinator: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let setupPipeline: MTLComputePipelineState
    let drawPipeline: MTLComputePipelineState

    let seedBuffer: MTLBuffer
    let stateBuffer: MTLBuffer

    var texture: MTLTexture?

    let width = 1024
    let height = 1024

    init?(_ device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        guard let device,
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let setupFunction = library.makeFunction(name: "setup_kernel"),
              let drawFunction = library.makeFunction(name: "random_color_kernel")
        else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue

        do {
            setupPipeline = try device.makeComputePipelineState(function: setupFunction)
            drawPipeline = try device.makeComputePipelineState(function: drawFunction)
        } catch {
            print("Pipeline error: \(error)")
            return nil
        }

        let stateSize = MemoryLayout<UInt32>.stride * 6
        stateBuffer = device.makeBuffer(length: width * height * stateSize, options: [])!

        var seed = UInt32(12345)
        seedBuffer = device.makeBuffer(bytes: &seed, length: MemoryLayout<UInt32>.stride, options: [])!
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
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }

        if texture == nil {
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                width: width,
                                                                height: height,
                                                                mipmapped: false)
            desc.usage = [.shaderWrite, .shaderRead]
            texture = device.makeTexture(descriptor: desc)
        }

        encoder.setComputePipelineState(drawPipeline)
        encoder.setTexture(texture, index: 0)
        encoder.setBuffer(stateBuffer, offset: 0, index: 0)

        let threadsPerGrid = MTLSize(width: width, height: height, depth: 1)
        let w = drawPipeline.threadExecutionWidth
        let h = drawPipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()

        let drawableTexture = drawable.texture
        if  let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
            blitEncoder.copy(from: texture!,
                             sourceSlice: 0,
                             sourceLevel: 0,
                             sourceOrigin: MTLOrigin.init(x: 0, y: 0, z: 0),
                             sourceSize: MTLSize(width: width, height: height, depth: 1),
                             to: drawableTexture,
                             destinationSlice: 0,
                             destinationLevel: 0,
                             destinationOrigin: MTLOrigin.init(x: 0, y: 0, z: 0))
            blitEncoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
