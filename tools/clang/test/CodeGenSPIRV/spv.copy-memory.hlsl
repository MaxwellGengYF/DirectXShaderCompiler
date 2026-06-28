// RUN: %dxc -T cs_6_0 -E main -spirv -HV 202x -Od %s | FileCheck %s

// ===== Test 1: Basic OpCopyMemory (single int) =====
[[vk::ext_instruction(63, "")]]
void __builtin_spirv_copy_memory([[vk::ext_reference]] inout int target,
                                 [[vk::ext_reference]] in int source);

// ===== Test 2: OpCopyMemory with memory operand =====
[[vk::ext_instruction(63, "")]]
void __builtin_spirv_copy_memory_masked(
    [[vk::ext_reference]] inout int target,
    [[vk::ext_reference]] in int source,
    [[vk::ext_literal]] uint mask);

// ===== Multi-element: struct copy (4 ints in one call) =====
struct Quad { int a; int b; int c; int d; };

[[vk::ext_instruction(63, "")]]
void __builtin_spirv_copy_quad([[vk::ext_reference]] inout Quad target,
                                [[vk::ext_reference]] in Quad source);

// ===== Multi-element: vector copy (int4 = 4 ints in one call) =====
[[vk::ext_instruction(63, "")]]
void __builtin_spirv_copy_int4([[vk::ext_reference]] inout int4 target,
                                [[vk::ext_reference]] in int4 source);

// ===== Buffer and groupshared test data =====
groupshared int gs_array[4];
groupshared Quad gs_quad;
RWStructuredBuffer<int> buf_out : register(u0);
RWStructuredBuffer<int> buf_in  : register(u1);

// CHECK: OpCapability Shader

[numthreads(1, 1, 1)]
void main(uint GI : SV_GroupIndex) {
    int a = 42;
    int b;

    // ========== Single element tests ==========

    // Test 1: Basic OpCopyMemory (int)
    // CHECK: OpCopyMemory %b %a
    __builtin_spirv_copy_memory(b, a);

    // Test 2: OpCopyMemory with Volatile memory operand
    // CHECK-NEXT: OpCopyMemory %b %a Volatile
    __builtin_spirv_copy_memory_masked(b, a, 1);

    // ========== Multi-element tests ==========

    // Test 3: Struct copy (Quad = 4 ints) - local to local
    // OpCopyMemory copies sizeof(Quad) = 16 bytes in one instruction
    Quad q1 = { 1, 2, 3, 4 };
    Quad q2;
    // CHECK: OpCopyMemory
    __builtin_spirv_copy_quad(q2, q1);

    // Test 4: Struct copy - groupshared Quad to local Quad
    // CHECK: OpCopyMemory
    __builtin_spirv_copy_quad(q2, gs_quad);

    // Test 5: Struct copy - local Quad to groupshared Quad
    // CHECK: OpCopyMemory
    __builtin_spirv_copy_quad(gs_quad, q1);

    // Test 6: Vector copy (int4 = 4 ints) - local to local
    int4 v1 = int4(10, 20, 30, 40);
    int4 v2 = int4(0, 0, 0, 0);
    // CHECK: OpCopyMemory
    __builtin_spirv_copy_int4(v2, v1);

    // Test 7: groupshared element copy (single int, existing)
    // CHECK: OpCopyMemory %b {{%[0-9]+}}
    __builtin_spirv_copy_memory(b, gs_array[0]);

    // Test 8: local to groupshared element
    // CHECK: OpCopyMemory {{%[0-9]+}} %a
    __builtin_spirv_copy_memory(gs_array[1], a);

    // Test 9: buffer element to local
    // CHECK: OpCopyMemory %b {{%[0-9]+}}
    __builtin_spirv_copy_memory(b, buf_in[0]);

    // Test 10: local to buffer element
    // CHECK: OpCopyMemory {{%[0-9]+}} %a
    __builtin_spirv_copy_memory(buf_out[0], a);

    // Test 11: buffer element to buffer element
    // CHECK: OpCopyMemory {{%[0-9]+}} {{%[0-9]+}}
    __builtin_spirv_copy_memory(buf_out[1], buf_in[1]);

    // Test 12: Cross storage-class: groupshared to buffer
    // CHECK: OpCopyMemory {{%[0-9]+}} {{%[0-9]+}}
    __builtin_spirv_copy_memory(buf_out[2], gs_array[0]);

    // Test 13: Cross storage-class: buffer to groupshared
    // CHECK: OpCopyMemory {{%[0-9]+}} {{%[0-9]+}}
    __builtin_spirv_copy_memory(gs_array[0], buf_in[2]);
}
