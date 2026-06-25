// RUN: %dxc -fspv-target-env=vulkan1.3 -T cs_6_0 -E main -spirv -Vd -HV 2021 %s | FileCheck %s

#include <vk/nv/cooperative_matrix2.h>

RWStructuredBuffer<float> data;
int stride;

// CHECK: OpCapability CooperativeMatrixReductionsNV
// CHECK: OpExtension "SPV_NV_cooperative_matrix2"

[numthreads(64, 1, 1)] void main() {
  using FloatMatAcc =
      vk::khr::CooperativeMatrixAccumulator<float, vk::ScopeSubgroup, 16, 8>;

  // Load an Accumulator matrix
  // CHECK: OpCooperativeMatrixLoadKHR
  FloatMatAcc acc_mat = FloatMatAcc::Load<vk::CooperativeMatrixLayoutRowMajorKHR>(
      data, 0, stride);

  // Row reduction: reduce each row using FAdd (129)
  // CHECK: OpCooperativeMatrixReduceNV %spirvIntrinsicType{{(_0)?}} {{%[^ ]+}} Row %uint_129
  auto row_result =
      vk::nv::cooperativeMatrixReduceRow<
          float, vk::ScopeSubgroup, 16, 8,
          vk::CooperativeMatrixUseMatrixAccumulatorKHR>(acc_mat, 129);

  // Column reduction: reduce each column using FAdd (129)
  // CHECK: OpCooperativeMatrixReduceNV %spirvIntrinsicType{{(_0)?}} {{%[^ ]+}} Column %uint_129
  auto col_result =
      vk::nv::cooperativeMatrixReduceColumn<
          float, vk::ScopeSubgroup, 16, 8,
          vk::CooperativeMatrixUseMatrixAccumulatorKHR>(acc_mat, 129);

  // 2x2 reduction: reduce 2x2 neighborhoods using FAdd (129)
  // CHECK: OpCooperativeMatrixReduceNV %spirvIntrinsicType_0 {{%[^ ]+}} 2x2 %uint_129
  auto mat_result = vk::nv::cooperativeMatrixReduce2x2<
      float, vk::ScopeSubgroup, 16, 8,
      vk::CooperativeMatrixUseMatrixAccumulatorKHR>(acc_mat, 129);
}
