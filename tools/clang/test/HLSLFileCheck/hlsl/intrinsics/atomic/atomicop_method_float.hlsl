// RUN: %dxc -T ps_6_6 %s | FileCheck %s

RWByteAddressBuffer res;

int main( float a : A) : SV_Target
{
  // Test atomic binop intrinsics with floats.
  // InterlockedAdd/Min/Max now have float overloads that bitcast to i32.
  // InterlockedAnd/Or/Xor with float args still resolve to int overloads.
  // All produce i32 DXIL operations; there is no f32 atomic bin op.

  uint ix = 0;
  int b;
  float c;

  // All six produce i32 atomic operations.
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  res.InterlockedAdd(ix, a);
  res.InterlockedMin(ix, a);
  res.InterlockedMax(ix, a);
  res.InterlockedAnd(ix, a);
  res.InterlockedOr(ix, a);
  res.InterlockedXor(ix, a);

  // With original value output. Float overloads output float, int overloads output int.
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  // CHECK: call i32 @dx.op.atomicBinOp.i32
  res.InterlockedAdd(ix, a, c);
  res.InterlockedMin(ix, a, c);
  res.InterlockedMax(ix, a, c);
  res.InterlockedAnd(ix, a, b);
  res.InterlockedOr(ix, a, b);
  res.InterlockedXor(ix, a, b);

  // CHECK-NOT: dx.op.atomicBinOp.f32
  return b;
}

