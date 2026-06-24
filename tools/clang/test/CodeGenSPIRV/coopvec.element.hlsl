// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd %s | FileCheck %s

#include <vk/nv/cooperative_vector.h>

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

[numthreads(64, 1, 1)] void main() {
  using CoopVec = vk::nv::CooperativeVector<float, 8>;

  // CHECK: OpCompositeConstruct %spirvIntrinsicType
  CoopVec v = CoopVec::Splat(0.0);

  // GetLength returns 8 (compile-time constant)
  uint32_t len = CoopVec::GetLength();
}
