// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -HV 2021 -Vd %s | FileCheck %s

#include <vk/nv/cooperative_vector.h>

ByteAddressBuffer matrixBuffer;

// CHECK: OpCapability CooperativeVectorNV
// CHECK: OpExtension "SPV_NV_cooperative_vector"

[numthreads(64, 1, 1)] void main() {
  using InputVec = vk::nv::CooperativeVector<float, 4>;
  using ResultVec = vk::nv::CooperativeVector<float, 8>;

  InputVec input = InputVec::Splat(0.5);

  // CHECK: OpCooperativeVectorMatrixMulNV
  ResultVec result = vk::nv::cooperativeVectorMatrixMul<float, float, 8, 4>(
      input,
      /*inputInterpretation*/ 0,
      matrixBuffer, /*matrixOffset*/ 0,
      /*matrixInterpretation*/ 0,
      /*stride*/ 64,
      vk::CooperativeVectorMatrixLayoutRowMajorNV,
      /*transpose*/ false);
}
