// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_9 -E main -spirv -HV 2021 %s | FileCheck %s

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

#include <vk/nv/cooperative_vector.h>

RWStructuredBuffer<float> buf : register(u0);

[numthreads(64, 1, 1)]
void main() {
  using FloatVec = vk::nv::CooperativeVector<float, 8>;

  // CHECK: OpCooperativeVectorLoadNV
  FloatVec v = FloatVec::Load(buf, 0);

  // CHECK: OpCooperativeVectorStoreNV
  v.Store(buf, 16);
}
