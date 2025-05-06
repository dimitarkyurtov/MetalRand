#include "MetalRand.metal"

using namespace metal;

/// Kernel to initialize RNG states.
kernel void setup_kernel(device metalrand::XORWOWState *states [[buffer(0)]],
                         constant uint &seed [[buffer(1)]],
                         uint thread_id [[thread_position_in_grid]]) {
    uint sequence = thread_id;
    metalrand::metalRandInit(seed, sequence, states[thread_id]);
}

/// Kernel to generate N random numbers.
kernel void generate_random_numbers(device metalrand::XORWOWState *states [[buffer(0)]],
                                    device float *output [[buffer(1)]],
                                    constant uint &N [[buffer(2)]],
                                    uint thread_id [[thread_position_in_grid]]) {
    
    thread metalrand::XORWOWState localState = states[thread_id];
    metalrand::XORWOW rng(localState);

    uint base_index = thread_id * N;
    for (uint i = 0; i < N; ++i) {
        output[base_index + i] = static_cast<float>(rng.next()) / static_cast<float>(0xFFFFFFFFu);
    }
    
    states[thread_id] = localState;
}


struct VertexOut {
    float4 position [[position]];
    uint2 gid;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                              constant uint2 &viewportSize [[buffer(0)]]) {
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2(3.0, -1.0),
        float2(-1.0, 3.0)
    };

    float2 screenPos = positions[vertexID] * 0.5 + 0.5;
    uint2 gid = uint2(screenPos * float2(viewportSize));

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.gid = gid;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              device metalrand::XORWOWState *states [[buffer(0)]],
                              constant uint &width [[buffer(1)]]) {
    uint thread_id = in.gid.y * width + in.gid.x;

    metalrand::XORWOWState localState = states[thread_id];
    metalrand::XORWOW rng(localState);

    float r = float(rng.next()) / 0xFFFFFFFFu;
    float g = float(rng.next()) / 0xFFFFFFFFu;
    float b = float(rng.next()) / 0xFFFFFFFFu;

    states[thread_id] = localState;

    return float4(r, g, b, 1.0);
}
