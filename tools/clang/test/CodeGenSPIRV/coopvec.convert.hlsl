// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd %s | FileCheck %s

#include <vk/nv/cooperative_vector.h>

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

[numthreads(64, 1, 1)] void main() {
  using CoopVecF = vk::nv::CooperativeVector<float, 8>;
  using CoopVecI = vk::nv::CooperativeVector<int, 8>;

  CoopVecF vf = CoopVecF::Splat(1.0);

  // CHECK: OpConvertFToS
  CoopVecI vi = vf.cast<int>();
}
