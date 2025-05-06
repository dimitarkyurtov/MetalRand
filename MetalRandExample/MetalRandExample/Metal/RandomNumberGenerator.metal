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

    metalrand::XORWOW rng(states[thread_id]);

    uint base_index = thread_id * N;
    for (uint i = 0; i < N; ++i) {
        output[base_index + i] = static_cast<float>(rng.next()) / static_cast<float>(0xFFFFFFFFu);
    }
}


kernel void random_color_kernel(texture2d<float, access::write> outTexture [[texture(0)]],
                                device metalrand::XORWOWState *states [[buffer(0)]],
                                uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    uint thread_id = gid.y * outTexture.get_width() + gid.x;

    metalrand::XORWOW rng(states[thread_id]);

    float r = static_cast<float>(rng.next()) / 0xFFFFFFFFu;
    float g = static_cast<float>(rng.next()) / 0xFFFFFFFFu;
    float b = static_cast<float>(rng.next()) / 0xFFFFFFFFu;

    outTexture.write(float4(b, g, r, 1.0), gid);
}
