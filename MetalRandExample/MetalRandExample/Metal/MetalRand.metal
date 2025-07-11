//
//  MetalRand.metal
//  MetalRand
//
//  Created by Dimitar Kyurtov on 3.05.25.
//

#include <metal_stdlib>
using namespace metal;

namespace metalrand {
    struct XORWOWState {
        uint32_t x, y, z, w, v, d;
    };
    
    /// Returns a random uint.
    inline uint metalRand(thread XORWOWState &state) {
        uint t = state.x ^ (state.x >> 2);
        state.x = state.y;
        state.y = state.z;
        state.z = state.w;
        state.w = state.v;
        state.v = (state.v ^ (state.v << 4)) ^ (t ^ (t << 1));
        state.d += 362437;
        return state.v + state.d;
    }

    /// Initializes a state with seed and sequence.
    inline void metalRandInit(uint seed, uint sequence, thread XORWOWState &state) {
        state.x = seed ^ 0xA341316C ^ sequence;
        state.y = seed ^ 0xC8013EA4 ^ (sequence << 1);
        state.z = seed ^ 0xAD90777D ^ (sequence >> 1);
        state.w = seed ^ 0x7E95761E ^ (~sequence);
        state.v = seed ^ 0xBA77B11E;
        state.d = 362437;
        
        for (uint i = 0; i < sequence; i ++) {
            metalrand::metalRand(state);
        }
    }
}

namespace metalrand {
    struct SplitMix32State {
        uint x;
    };
    
    inline uint metalRand(thread SplitMix32State &state) {
        uint z = state.x + 0x9E3779B9;
        state.x = z;
        z = (z ^ (z >> 15)) * 0x85EBCA6B;
        z = (z ^ (z >> 13)) * 0xC2B2AE35;
        return int(z ^ (z >> 16));
    }

    inline void metalRandInit(uint seed, uint sequence, thread SplitMix32State &state) {
        state.x = seed + sequence * 0x9E3779B9;
        
        for (uint i = 0; i < sequence; i ++) {
            metalrand::metalRand(state);
        }
    }
}

namespace metalrand {
    struct Xoroshiro32State {
        uint s0;
        uint s1;
    };
    
    inline uint metalRand(thread Xoroshiro32State& state) {
        uint s0 = state.s0;
        uint s1 = state.s1;

        s1 ^= s0;
        state.s0 = (s0 << 13) | (s0 >> (32 - 13));
        state.s0 ^= s1 ^ (s1 << 9);
        state.s1 = (s1 << 17) | (s1 >> (32 - 17));

        return s0 + s1;
    }

    inline void metalRandInit(uint seed, uint sequence, thread Xoroshiro32State &state) {
        SplitMix32State sm;
        metalRandInit(seed, sequence, sm);
        state.s0 = metalRand(sm);
        state.s1 = metalRand(sm);
        
        for (uint i = 0; i < sequence; i ++) {
            metalrand::metalRand(state);
        }
    }
}
