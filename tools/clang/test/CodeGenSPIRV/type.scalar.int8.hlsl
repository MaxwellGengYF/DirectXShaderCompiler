// RUN: %dxc -T ps_6_2 -HV 2018 -E main -spirv %s | FileCheck %s

// CHECK: OpCapability Int8

void main() {
  int8_t  a = 5;
  uint8_t b = 255;
  int8_t  c = -128;
  int8_t2 d = int8_t2(1, 2);
  uint8_t4 e = uint8_t4(3, 4, 5, 6);
}
