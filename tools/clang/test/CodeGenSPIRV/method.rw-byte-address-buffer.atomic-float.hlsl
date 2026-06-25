// RUN: not %dxc -T cs_6_6 -E main -fcgl %s -spirv 2>&1 | FileCheck %s

RWByteAddressBuffer buf;

[numthreads(1,1,1)]
void main()
{
  float original_f_val;
  float val_f;

  // Float InterlockedMin/Max on RWByteAddressBuffer is not supported in SPIR-V
  // because the underlying buffer is an array of uints.

  // CHECK: error: Float InterlockedMin/Max on RWByteAddressBuffer is not supported in SPIR-V
  buf.InterlockedMin(0, val_f);

  // CHECK: error: Float InterlockedMin/Max on RWByteAddressBuffer is not supported in SPIR-V
  buf.InterlockedMax(0, val_f);
}
