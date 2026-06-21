// RUN: %dxc -T ps_6_2 -HV 2018 -E main -spirv %s | FileCheck %s

// CHECK: OpCapability Int8

void main() {
  int8_t2  a;
  int8_t3  b;
  int8_t4  c;
  uint8_t2 d;
  uint8_t3 e;
  uint8_t4 f;
}
