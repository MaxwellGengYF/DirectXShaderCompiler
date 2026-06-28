
[[vk::ext_instruction(4434, "")]]
[[vk::ext_capability(4473)]]
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

[numthreads(1, 1, 1)]
void main() {
    uint e;
    e = __builtin_spirv_group_async_copy(2, gs_buf[0], gs_buf[1], 4, 1, 4, 0);
}
