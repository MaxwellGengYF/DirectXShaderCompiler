// RUN: %dxc -T cs_6_0 -E main -spirv -HV 202x -Od -fspv-print-all %s | FileCheck %s
//
// OpUntypedGroupAsyncCopyKHR emission test.
// NOTE: Validates instruction/capability/extension emission only.
// Full SPIR-V validation requires OpTypeUntypedPointerKHR operands,
// which needs the separate SPV_KHR_untyped_pointers type infra.

[[vk::ext_instruction(4434, "")]]
[[vk::ext_capability(/*UntypedPointersKHR*/ 4473)]]
[[vk::ext_extension("SPV_KHR_untyped_pointers")]]
uint __builtin_spirv_group_async_copy(
    uint execution_scope,
    [[vk::ext_reference]] inout uint destination,
    [[vk::ext_reference]] in uint source,
    uint element_num_bytes,
    uint num_elements,
    uint stride,
    uint event
);

groupshared uint gs_buf[64];

// CHECK: OpCapability UntypedPointersKHR
// CHECK: OpExtension "SPV_KHR_untyped_pointers"
// CHECK: OpUntypedGroupAsyncCopyKHR
[numthreads(1, 1, 1)]
void main() {
    uint e;
    e = __builtin_spirv_group_async_copy(2, gs_buf[0], gs_buf[1], 4, 1, 4, 0);
}
