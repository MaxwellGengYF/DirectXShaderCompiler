// RUN: not %dxc -T ps_6_2 -HV 2018 -E main %s 2>&1 | FileCheck %s

// CHECK: int8_t is only supported with -spirv

void main() {
    int8_t a = 5;
}
