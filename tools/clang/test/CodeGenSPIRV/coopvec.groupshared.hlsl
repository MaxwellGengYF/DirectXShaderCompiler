// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd %s | FileCheck %s

#include <vk/nv/cooperative_vector.h>

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

[numthreads(64, 1, 1)] void main() {
  // Test that the cooperative vector type can be declared and used with groupshared memory.
  // The actual workgroup load/store via WorkgroupSpirvPointer is not yet functional.
  using CoopVec = vk::nv::CooperativeVector<float, 8>;
  CoopVec v;
}
