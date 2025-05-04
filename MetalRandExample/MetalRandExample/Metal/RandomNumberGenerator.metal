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
