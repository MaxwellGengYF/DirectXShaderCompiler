// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 %s | FileCheck %s
// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -DTYPE=float %s | FileCheck %s --check-prefix=CHECK-FLOAT
// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -DTYPE=int %s | FileCheck %s --check-prefix=CHECK-INT
// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -DTYPE=uint %s | FileCheck %s --check-prefix=CHECK-UINT

#include <vk/nv/cooperative_vector.h>

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

// CHECK-FLOAT: {{%[^ ]+}} = OpType{{CooperativeVectorNV|VectorIdEXT}} %float %uint_8
// CHECK-INT: {{%[^ ]+}} = OpType{{CooperativeVectorNV|VectorIdEXT}} %int %uint_8
// CHECK-UINT: {{%[^ ]+}} = OpType{{CooperativeVectorNV|VectorIdEXT}} %uint %uint_8

[numthreads(64, 1, 1)] void main() {
// Default: float
#ifndef TYPE
#define TYPE float
#endif
  using CoopVec = vk::nv::CooperativeVector<TYPE, 8>;
  CoopVec v;
}
