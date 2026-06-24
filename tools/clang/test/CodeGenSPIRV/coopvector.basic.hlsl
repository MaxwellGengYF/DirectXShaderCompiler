// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_9 -E main -spirv -HV 2021 -enable-16bit-types %s | FileCheck %s

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

// Minimal cooperative vector test with 16-bit types enabled
#include <vk/nv/cooperative_vector.h>

RWStructuredBuffer<float> buf : register(u0);

[numthreads(64, 1, 1)]
void main() {
  using FloatVec = vk::nv::CooperativeVector<float, 8>;
  FloatVec v = FloatVec::Load(buf, 0);
  v.Store(buf, 16);
}
