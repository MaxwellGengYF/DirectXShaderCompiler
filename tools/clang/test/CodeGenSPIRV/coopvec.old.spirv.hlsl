// RUN: not %dxc -fspv-target-env=vulkan1.0 -T cs_6_0 -E main -spirv -HV 2021 %s 2>&1 | FileCheck %s

#include <vk/nv/cooperative_vector.h>

// CHECK: CooperativeVector requires a minimum of SPIR-V 1.6

[numthreads(64, 1, 1)] void main() {
}
