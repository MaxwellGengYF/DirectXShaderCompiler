// RUN: %dxc -T cs_6_0 -E main -spirv -HV 202x -Od %s | FileCheck %s

// ===== Single element: Basic OpCopyMemory (int) =====
[[vk::ext_instruction(63, "")]]
void __builtin_spirv_copy_memory([[vk::ext_reference]] inout int target,
                                 [[vk::ext_reference]] in int source);

// ===== Single element: OpCopyMemory with memory operand =====
[[vk::ext_instruction(63, "")]]
void __builtin_spirv_copy_memory_masked(
    [[vk::ext_reference]] inout int target,
    [[vk::ext_reference]] in int source,
    [[vk::ext_literal]] uint mask);

// ===== Multi-element: struct copy (Quad = 4 ints in one call) =====
struct Quad { int a; int b; int c; int d; };

[[vk::ext_instruction(63, "")]]
void __builtin_spirv_copy_quad([[vk::ext_reference]] inout Quad target,
                                [[vk::ext_reference]] in Quad source);

// ===== Multi-element: vector copy (int4 = 4 ints in one call) =====
[[vk::ext_instruction(63, "")]]
void __builtin_spirv_copy_int4([[vk::ext_reference]] inout int4 target,
                                [[vk::ext_reference]] in int4 source);

// ===== Test data =====
groupshared int gs_array[4];
groupshared Quad gs_quad;
RWStructuredBuffer<int> buf_out : register(u0);
RWStructuredBuffer<int> buf_in  : register(u1);

// CHECK: OpCapability Shader

[numthreads(1, 1, 1)]
void main(uint GI : SV_GroupIndex) {
    int a = 42;
    int b;

    // ========== Single element (Function storage class) ==========

    // Test 1: local -> local (Function -> Function)
    // CHECK: OpCopyMemory %b %a
    __builtin_spirv_copy_memory(b, a);

    // Test 2: with Volatile memory operand
    // CHECK-NEXT: OpCopyMemory %b %a Volatile
    __builtin_spirv_copy_memory_masked(b, a, 1);

    // ========== Multi-element via composite types ==========

    // Test 3: struct copy (Quad = 4 ints, 16 bytes in one OpCopyMemory)
    Quad q1 = { 1, 2, 3, 4 };
    Quad q2;
    // CHECK: OpCopyMemory
    __builtin_spirv_copy_quad(q2, q1);

    // Test 4: groupshared struct -> local struct (Workgroup -> Function)
    // CHECK: OpCopyMemory
    __builtin_spirv_copy_quad(q2, gs_quad);

    // Test 5: local struct -> groupshared struct (Function -> Workgroup)
    // CHECK: OpCopyMemory
    __builtin_spirv_copy_quad(gs_quad, q1);

    // Test 6: vector copy (int4 = 4 ints, 16 bytes in one OpCopyMemory)
    int4 v1 = int4(10, 20, 30, 40);
    int4 v2 = int4(0, 0, 0, 0);
    // CHECK: OpCopyMemory
    __builtin_spirv_copy_int4(v2, v1);

    // ========== groupshared (Workgroup storage class) ==========

    // Test 7: groupshared[0] -> local (Workgroup -> Function)
    // CHECK: OpCopyMemory %b {{%[0-9]+}}
    __builtin_spirv_copy_memory(b, gs_array[0]);

    // Test 8: local -> groupshared[1] (Function -> Workgroup)
    // CHECK: OpCopyMemory {{%[0-9]+}} %a
    __builtin_spirv_copy_memory(gs_array[1], a);

    // Test 9: groupshared[0] -> groupshared[2] (Workgroup -> Workgroup)
    // CHECK: OpCopyMemory {{%[0-9]+}} {{%[0-9]+}}
    __builtin_spirv_copy_memory(gs_array[2], gs_array[0]);

    // Test 10: groupshared[GI] -> groupshared[3] (Workgroup -> Workgroup, dynamic index)
    // CHECK: OpCopyMemory {{%[0-9]+}} {{%[0-9]+}}
    __builtin_spirv_copy_memory(gs_array[3], gs_array[GI]);

    // ========== RWStructuredBuffer (Uniform storage class) ==========

    // Test 11: buffer[0] -> local (StorageBuffer -> Function)
    // CHECK: OpCopyMemory %b {{%[0-9]+}}
    __builtin_spirv_copy_memory(b, buf_in[0]);

    // Test 12: local -> buffer[0] (Function -> StorageBuffer)
    // CHECK: OpCopyMemory {{%[0-9]+}} %a
    __builtin_spirv_copy_memory(buf_out[0], a);

    // Test 13: buffer[1] -> buffer[1] (StorageBuffer -> StorageBuffer)
    // CHECK: OpCopyMemory {{%[0-9]+}} {{%[0-9]+}}
    __builtin_spirv_copy_memory(buf_out[1], buf_in[1]);

    // ========== Cross storage-class ==========

    // Test 14: groupshared[0] -> buffer[2] (Workgroup -> StorageBuffer)
    // CHECK: OpCopyMemory {{%[0-9]+}} {{%[0-9]+}}
    __builtin_spirv_copy_memory(buf_out[2], gs_array[0]);

    // Test 15: buffer[2] -> groupshared[0] (StorageBuffer -> Workgroup)
    // CHECK: OpCopyMemory {{%[0-9]+}} {{%[0-9]+}}
    __builtin_spirv_copy_memory(gs_array[0], buf_in[2]);
}
