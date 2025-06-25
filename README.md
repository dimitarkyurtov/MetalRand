## Introduction

Random number generation is an important part of computing, used across a broad range of fields - for example cryptography, simulations, procedural content generation, and graphics. Random numbers can be categorized into two main types: **true random numbers**, which are derived from physical sources of entropy (like electrical noise, nuclear atoms decay, etc.), and **pseudo-random numbers**, which are generated algorithmically/deterministically and preserve properties of true random numbers. While true random number generation offers high entropy, pseudo-random number generators (PRNGs) are often used due to their speed and reproducibility. PRNGs can be generated with software while true random numbers require a specialized hardware.

Random numbers are used in pretty much every complex computer program. Some common use cases are:
1. Monte Carlo Simulations
    - Purpose: Estimate numerical results through random sampling.
    - Use Case: Physics simulations, financial modeling, risk analysis.
    - Example: Estimating the value of π by randomly sampling points in a square and checking how many fall inside an inscribed circle.
2. Games and Procedural Generation
    - Purpose: Introduce unpredictability and generate content on the fly.
    - Use Case: Game mechanics (e.g., dice rolls, loot drops), procedural worlds, terrain generation.
 3. Cryptography
    - Purpose: Ensure unpredictability and security.
    - Use Case: Key generation, nonce creation, salt in hashing.

Offering RNG in multithreaded environment is challenging due to snchronization and data managements. If 2 or more threads use the same RNG, its properties and compromised. That is why most programming languages do not support multithreaded RNGs. In GPU programming in order to use RNGs a multithreaded support is required due to their SIMD architecture. The is why GPU vendors supply such RNGs as part of their standard libraries - an example is **cuRAND** by CUDA. However Metal - latest Apple GPU framework targetted at their latest architecture does not have such support.

The aim of this project is to fill this gap by developing **MetalRand**, a GPU-based random number generation library written in Metal shading language. Inspired by the cuRand library, MetalRand enables each GPU thread to manage its own independent random number generator.

This library provides a simple interface for initializing per-thread random states and generating random 32-bit integers. It supports three different random number generation algorithms—**XORWOW**, **SplitMix32**, and **Xoroshiro32** — each represented by a dedicated state structure. A sample application has also been developed to demonstrate the usage of MetalRand by generating a random color for each pixel on every frame.

---

## Implementation

### Overview

MetalRand is implemented as a single `.metal` file, making it easy to include and integrate into any Metal project. The library offers the ability for each GPU thread to independently generate random numbers using one of three supported algorithms.

### Algorithms Supported

- **XORWOW**: variation of the Xorshift family of generators with an added Weyl sequence component to improve its period and statistical properties. It operates using a series of XOR and bit-shift operations on multiple 32-bit state values. The algorithm offers a very long period (~2^192) and is known for being both fast and statistically robust.
- **SplitMix32**: non-cryptographic PRNG algorithm without a high quality of randomness. It works by incrementing a counter and transforming it through a sequence of bit shifts and multiplications. While it’s not suitable for security-sensitive applications, it performs well for internal PRNG.
- **Xoroshiro32**: based on the Xoroshiro family, optimized for 32-bit output. It combines XOR and rotation operations on a small internal state to produce high-quality pseudo-random numbers. Xoroshiro generators are known for their balance between speed and randomness quality.

Each algorithm has an associated `State` structure, which maintains the internal state required to generate the next random number.

### API Description

#### Initialization

```metal
void metalRandInit(uint seed, uint sequence, thread State &state);
```

- `seed`: A random seed used for the initial State generation. This is a random value which can be common among threads. Should be generated with `SecRandomCopyBytes`, which accesses hardware true random number generator on Apple devices.
- `sequence`: A unique identifier used for the initial State generation. It is used to initialize each threads State with different values (so they don't generate the same sequence). It should be unique between the threads. Typically the `thread_id`.
- `state`: The state object that holds the internal state of the generator. Must be allocated before the call.

This function must be called once per thread before any random number generation. Typically you lauch a separate kernell call for setting up all the state before any render pipelines.

#### Random Number Generation

```metal
uint metalRand(thread State &state);
```
- Returns a random 32-bit unsigned integer.
- Uses the provided `state` to generate the next number in the sequence.

### Example Application

A sample Metal application is included to demonstrate the usage of the MetalRand library. It utilizes a GPU kernel where each thread generates a random color using its own RNG state. This color is then used to shade a corresponding pixel.

Videos demonstrating the output of this application are available in the repository under the [videos](/videos) folder.

---

## Conclusion

This project presents **MetalRand**, a lightweight GPU random number generation library for Metal that supports per-thread PRNGs using multiple algorithms. It provides essential functionality missing in the Metal standard library, enabling richer and more flexible GPU-side computations.

Future development could extend MetalRand to support:
- Generation of random values for more types - 16bit int, floating point, etc.
- Sampling from statistical distributions (e.g., Gaussian, Poisson).
- Utility functions to generate large number of random numbers and return them to the CPU (no client side GPU code required).
