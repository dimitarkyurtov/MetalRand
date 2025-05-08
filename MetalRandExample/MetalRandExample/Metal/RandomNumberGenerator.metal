#include "MetalRand.metal"

using namespace metal;

/// Kernel to initialize RNG states.
kernel void setup_kernel(device metalrand::XORWOWState *states [[buffer(0)]],
                         constant uint &seed [[buffer(1)]],
                         constant uint &width [[buffer(2)]],
                         uint2 gid [[thread_position_in_grid]]) {

    uint thread_id = gid.y * width + gid.x;
    metalRandInit(seed, thread_id, states[thread_id]);
}

/// Vertex shader which draws on the whole screen.
vertex float4 vertex_main(uint vertexID [[vertex_id]]) {
    float2 pos[3] = { float2(-1, -1), float2(3, -1), float2(-1, 3) };
    return float4(pos[vertexID], 0, 1);
}

/// Fragment shader which generates a random value for each pixel.
fragment float4 fragment_main(float4 position [[position]],
                              device metalrand::XORWOWState *states [[buffer(0)]],
                              constant uint &width [[buffer(1)]]) {
    uint2 gid = uint2(position.xy);
    uint thread_id = gid.y * width + gid.x;

    metalrand::XORWOWState localState = states[thread_id];
    metalrand::XORWOW rng(localState);

    float r = float(rng.next()) / 0xFFFFFFFFu;
    float g = float(rng.next()) / 0xFFFFFFFFu;
    float b = float(rng.next()) / 0xFFFFFFFFu;

    states[thread_id] = localState;

    return float4(r, g, b, 1.0);
}
