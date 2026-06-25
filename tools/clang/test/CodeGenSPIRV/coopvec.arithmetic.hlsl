// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd -DTYPE=float %s | FileCheck %s --check-prefix=CHECK --check-prefix=FLOATS
// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd -DTYPE=int %s | FileCheck %s --check-prefix=CHECK --check-prefix=INTEGERS
// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd -DTYPE=uint %s | FileCheck %s --check-prefix=CHECK --check-prefix=INTEGERS
// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd -DTYPE=double %s | FileCheck %s --check-prefix=CHECK --check-prefix=FLOATS

// NOTE: -Vd used to bypass SPIR-V validator bug with OpCompositeConstruct on cooperative vector types

#include <vk/nv/cooperative_vector.h>

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

[numthreads(64, 1, 1)] void main() {
  using CoopVec = vk::nv::CooperativeVector<TYPE, 4>;

  CoopVec v = CoopVec::Splat(TYPE(1));
  CoopVec v2 = CoopVec::Splat(TYPE(2));

  // INTEGERS: OpIAdd
  // FLOATS: OpFAdd
  CoopVec r = v + v2;

  // INTEGERS: OpISub
  // FLOATS: OpFSub
  CoopVec s = v - v2;

  // INTEGERS: OpSNegate
  // FLOATS: OpFNegate
  CoopVec n = v.negate();

  // INTEGERS: OpIMul
  // FLOATS: OpFMul
  CoopVec m = v * v2;

  // INTEGERS: Op{{[SU]}}Div
  // FLOATS: OpFDiv
  CoopVec d = v / v2;

  // CHECK: OpMatrixTimesScalar
  CoopVec t = v * TYPE(2);
}
