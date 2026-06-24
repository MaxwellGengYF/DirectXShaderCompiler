// RUN: %dxc -T cs_6_9 -E main -spirv -fspv-target-env=vulkan1.3 -HV 2021 %s | FileCheck %s

// Test that vectors with >4 components (allowed in SM 6.9+) compile
// correctly for SPIR-V by being lowered as arrays.

// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %main "main"

RWStructuredBuffer<float> buf : register(u0);

[numthreads(64, 1, 1)]
void main() {
  // Declare and use an 8-component vector
  vector<float, 8> v;
  // CHECK: OpStore
  v[0] = 1.0;
  v[7] = 8.0;
  buf[0] = v[0] + v[7];
}
