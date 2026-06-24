// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd %s | FileCheck %s

#include <vk/nv/cooperative_vector.h>

RWStructuredBuffer<float> data;

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

[numthreads(64, 1, 1)] void main() {
  using CoopVec = vk::nv::CooperativeVector<float, 8>;

  // CHECK: OpCooperativeVectorLoadNV
  CoopVec v = CoopVec::Load(data, 0);

  // CHECK: OpCooperativeVectorStoreNV
  v.Store(data, 0);
}
