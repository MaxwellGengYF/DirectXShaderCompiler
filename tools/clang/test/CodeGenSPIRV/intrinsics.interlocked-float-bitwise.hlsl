// RUN: not %dxc -T cs_6_6 -E main -fcgl %s -spirv 2>&1 | FileCheck %s

groupshared float dest_f;
RWBuffer<float> buff_f;
RWStructuredBuffer<float> sbuff_f;

[numthreads(1,1,1)]
void main()
{
  float original_f;
  float compare_val;
  float new_val;

  // CHECK: error: InterlockedCompareExchangeFloatBitwise and InterlockedCompareStoreFloatBitwise are only supported on RWByteAddressBuffer
  InterlockedCompareExchangeFloatBitwise(dest_f, compare_val, new_val, original_f);

  // CHECK: error: InterlockedCompareExchangeFloatBitwise and InterlockedCompareStoreFloatBitwise are only supported on RWByteAddressBuffer
  InterlockedCompareStoreFloatBitwise(dest_f, compare_val, new_val);

  // CHECK: error: InterlockedCompareExchangeFloatBitwise and InterlockedCompareStoreFloatBitwise are only supported on RWByteAddressBuffer
  InterlockedCompareExchangeFloatBitwise(buff_f[0], compare_val, new_val, original_f);

  // CHECK: error: InterlockedCompareExchangeFloatBitwise and InterlockedCompareStoreFloatBitwise are only supported on RWByteAddressBuffer
  InterlockedCompareExchangeFloatBitwise(sbuff_f[0], compare_val, new_val, original_f);
}
