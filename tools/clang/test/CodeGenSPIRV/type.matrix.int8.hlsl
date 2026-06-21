// RUN: %dxc -T ps_6_2 -HV 2018 -E main -spirv %s | FileCheck %s

// CHECK: OpCapability Int8

void main() {
  int8_t2x3 a;
  int8_t4x4 b;
  uint8_t2x3 c;
  uint8_t4x4 d;
}
