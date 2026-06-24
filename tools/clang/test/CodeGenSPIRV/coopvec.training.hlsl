// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd %s | FileCheck %s

#include <vk/nv/cooperative_vector.h>

ByteAddressBuffer buf;

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpCapability CooperativeVectorTrainingNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

[numthreads(64, 1, 1)] void main() {
  using CoopVec4 = vk::nv::CooperativeVector<float, 4>;
  using CoopVec8 = vk::nv::CooperativeVector<float, 8>;

  CoopVec4 v1 = CoopVec4::Splat(0.5);
  CoopVec8 v2 = CoopVec8::Splat(0.25);

  // CHECK: OpCooperativeVectorOuterProductAccumulateNV
  vk::nv::cooperativeVectorOuterProductAccumulate(
      v1, v2, buf, /*offset*/ 0, /*stride*/ 64,
      vk::CooperativeVectorMatrixLayoutTrainingOptimalNV,
      /*matrixInterpretation*/ 0);

  // CHECK: OpCooperativeVectorReduceSumAccumulateNV
  vk::nv::cooperativeVectorReduceSumAccumulate(v1, buf, /*offset*/ 0);
}
