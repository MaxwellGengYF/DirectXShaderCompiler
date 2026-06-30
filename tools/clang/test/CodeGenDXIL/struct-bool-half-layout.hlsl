// RUN: %dxc -T cs_6_2 -E main -fcgl -enable-16bit-types %s | FileCheck %s

// Test struct layout with bool :8 bitfields adjacent to 16-bit types.
// bool :8 should occupy 1 byte, half/int16_t/uint16_t occupy 2 bytes.

// A1: bool first, then half.
struct A1 {
    bool a : 8;
    float16_t b;
};
// CHECK-DAG: %struct.A1 = type { i8, half }

// A2: half first, then bool.
struct A2 {
    float16_t a;
    bool b : 8;
};
// CHECK-DAG: %struct.A2 = type { half, i8 }

// A3: interleaved bool, half, bool.
struct A3 {
    bool a : 8;
    float16_t b;
    bool c : 8;
};
// CHECK-DAG: %struct.A3 = type { i8, half, i8 }

// A4: bool, int16, bool, uint16.
struct A4 {
    bool a : 8;
    int16_t b;
    bool c : 8;
    uint16_t d;
};
// CHECK-DAG: %struct.A4 = type { i8, i16, i8, i16 }

// Nested structs
struct Inner {
    bool a : 8;
    float16_t b;
};
// CHECK-DAG: %struct.Inner = type { i8, half }

struct Outer {
    Inner c;
    float16_t d;
    bool e : 8;
};
// CHECK-DAG: %struct.Outer = type { %struct.Inner, half, i8 }

RWStructuredBuffer<float4> buf : register(u0);

[numthreads(1, 1, 1)]
void main() {
    A1 s1 = (A1)0;
    A2 s2 = (A2)0;
    A3 s3 = (A3)0;
    A4 s4 = (A4)0;
    Inner inner = (Inner)0;
    Outer outer = (Outer)0;

    s1.a = true;
    s2.b = true;
    s3.c = true;
    s4.d = 1;
    inner.a = true;
    outer.e = true;

    buf[0] = float4(s1.b, s2.b, s3.b, s4.d);
}
