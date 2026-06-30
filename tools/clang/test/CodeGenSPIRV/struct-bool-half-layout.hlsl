// RUN: %dxc -T cs_6_2 -E main -fcgl -enable-16bit-types -spirv %s | FileCheck %s

// Test struct layout with bool :8 bitfields adjacent to 16-bit types via SPIR-V path.
// bool :8 should occupy 1 byte, half/int16_t/uint16_t occupy 2 bytes.

//-----------------------------------------------------------------------------
// Category A: Simple Bool+Half/Int Structs
//-----------------------------------------------------------------------------

// A1: bool first, then half.
struct A1 {
    bool a : 8;
    float16_t b;
};

// A2: half first, then bool.
struct A2 {
    float16_t a;
    bool b : 8;
};

// A3: interleaved bool, half, bool.
struct A3 {
    bool a : 8;
    float16_t b;
    bool c : 8;
};

// A4: bool, int16, bool, uint16.
struct A4 {
    bool a : 8;
    int16_t b;
    bool c : 8;
    uint16_t d;
};

//-----------------------------------------------------------------------------
// Category B: Nested Structs
//-----------------------------------------------------------------------------

struct Inner {
    bool a : 8;
    float16_t b;
};

struct Outer {
    Inner c;
    float16_t d;
    bool e : 8;
};

//-----------------------------------------------------------------------------
// Use the structs in cbuffer to trigger SPIR-V codegen
//-----------------------------------------------------------------------------

cbuffer MyCB : register(b0) {
    A1 a1;
    A2 a2;
    A3 a3;
    A4 a4;
    Inner inner;
    Outer outer;
};

// Member offset decorations may be emitted in any order before the type
// definitions; use CHECK-DAG to match them.
// CHECK-DAG: OpMemberDecorate %A1 0 Offset 0
// CHECK-DAG: OpMemberDecorate %A1 1 Offset 2
// CHECK-DAG: OpMemberDecorate %A2 0 Offset 0
// CHECK-DAG: OpMemberDecorate %A2 1 Offset 2
// CHECK-DAG: OpMemberDecorate %A3 0 Offset 0
// CHECK-DAG: OpMemberDecorate %A3 1 Offset 2
// CHECK-DAG: OpMemberDecorate %A3 2 Offset 4
// CHECK-DAG: OpMemberDecorate %A4 0 Offset 0
// CHECK-DAG: OpMemberDecorate %A4 1 Offset 2
// CHECK-DAG: OpMemberDecorate %A4 2 Offset 4
// CHECK-DAG: OpMemberDecorate %A4 3 Offset 6
// CHECK-DAG: OpMemberDecorate %Inner 0 Offset 0
// CHECK-DAG: OpMemberDecorate %Inner 1 Offset 2
// CHECK-DAG: OpMemberDecorate %Outer 0 Offset 0
// CHECK-DAG: OpMemberDecorate %Outer 1 Offset 16
// CHECK-DAG: OpMemberDecorate %Outer 2 Offset 18

// CHECK-DAG: OpMemberDecorate %type_MyCB 0 Offset 0
// CHECK-DAG: OpMemberDecorate %type_MyCB 1 Offset 16
// CHECK-DAG: OpMemberDecorate %type_MyCB 2 Offset 32
// CHECK-DAG: OpMemberDecorate %type_MyCB 3 Offset 48
// CHECK-DAG: OpMemberDecorate %type_MyCB 4 Offset 64
// CHECK-DAG: OpMemberDecorate %type_MyCB 5 Offset 80

// CHECK-DAG: OpDecorate %type_MyCB Block

// The OpTypeStruct definitions are emitted after all decorations.
// CHECK: %A1 = OpTypeStruct %uchar %half
// CHECK: %A2 = OpTypeStruct %half %uchar
// CHECK: %A3 = OpTypeStruct %uchar %half %uchar
// CHECK: %A4 = OpTypeStruct %uchar %short %uchar %ushort
// CHECK: %Inner = OpTypeStruct %uchar %half
// CHECK: %Outer = OpTypeStruct %Inner %half %uchar
// CHECK: %type_MyCB = OpTypeStruct %A1 %A2 %A3 %A4 %Inner %Outer

[numthreads(1, 1, 1)]
void main() {
}
