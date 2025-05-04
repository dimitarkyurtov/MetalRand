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
        uint x, y, z, w, v, d;
    };

    class XORWOW {
        private:
            device XORWOWState &state;

        public:
            XORWOW(device XORWOWState &s) : state(s) {}

            uint next() thread {
                uint t = state.x ^ (state.x >> 2);
                state.x = state.y;
                state.y = state.z;
                state.z = state.w;
                state.w = state.v;
                state.v = (state.v ^ (state.v << 4)) ^ (t ^ (t << 1));
                state.d += 362437;
                return state.v + state.d;
            }
    };

    inline void metalRandInit(uint seed, uint sequence, device XORWOWState &state) {
        state.x = seed ^ 0xA341316C ^ sequence;
        state.y = seed ^ 0xC8013EA4 ^ (sequence << 1);
        state.z = seed ^ 0xAD90777D ^ (sequence >> 1);
        state.w = seed ^ 0x7E95761E ^ (~sequence);
        state.v = seed ^ 0xBA77B11E;
        state.d = 362437;
    }

    /// Returns a random float in [0, 1)
    inline float metalRand(device XORWOWState &state) {
        XORWOW rng(state);
        return static_cast<float>(rng.next()) / static_cast<float>(0xFFFFFFFFu);
    }

}
