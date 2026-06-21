// RUN: %dxc -T ps_6_2 -HV 2018 -E main -spirv -enable-16bit-types %s | FileCheck %s

// CHECK: OpCapability Int8

void main() {
  int8_t a = 5;
  uint8_t b = 255;
  
  int16_t c = (int16_t)a;
  int32_t d = (int32_t)a;
  int64_t e = (int64_t)a;
  
  uint16_t f = (uint16_t)b;
  uint32_t g = (uint32_t)b;
  uint64_t h = (uint64_t)b;
}
