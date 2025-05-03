//
//  MetalRand.metal
//  MetalRand
//
//  Created by Dimitar Kyurtov on 3.05.25.
//

#include <metal_stdlib>
using namespace metal;

kernel void hello_world(device char *output [[ buffer(0) ]],
                        uint id [[ thread_position_in_grid ]]) {
    const char msg[] = "Hello, GPU World!";
    if (id < sizeof(msg)) {
        output[id] = msg[id];
    }
}
