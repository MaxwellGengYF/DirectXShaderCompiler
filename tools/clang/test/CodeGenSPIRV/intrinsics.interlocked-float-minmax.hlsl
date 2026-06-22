// RUN: %dxc -T cs_6_6 -E main -fcgl %s -spirv | FileCheck %s

groupshared float dest_f;

[numthreads(1,1,1)]
void main()
{
  float original_f_val;
  float val_f;

// CHECK: OpCapability AtomicFloat32MinMaxEXT
// CHECK: OpExtension "SPV_EXT_shader_atomic_float_min_max"

  // Test InterlockedMin on groupshared float
// CHECK:      [[val:%[0-9]+]] = OpLoad %float %val_f
// CHECK-NEXT:  {{%[0-9]+}} = OpAtomicFMinEXT %float %dest_f %uint_2 %uint_0 [[val]]
  InterlockedMin(dest_f, val_f);

  // Test InterlockedMin on groupshared float with output original value
// CHECK:      [[val2:%[0-9]+]] = OpLoad %float %val_f
// CHECK-NEXT: [[orig:%[0-9]+]] = OpAtomicFMinEXT %float %dest_f %uint_2 %uint_0 [[val2]]
// CHECK-NEXT:                   OpStore %original_f_val [[orig]]
  InterlockedMin(dest_f, val_f, original_f_val);

  // Test InterlockedMax on groupshared float
// CHECK:      [[val3:%[0-9]+]] = OpLoad %float %val_f
// CHECK-NEXT:  {{%[0-9]+}} = OpAtomicFMaxEXT %float %dest_f %uint_2 %uint_0 [[val3]]
  InterlockedMax(dest_f, val_f);

  // Test InterlockedMax on groupshared float with output original value
// CHECK:      [[val4:%[0-9]+]] = OpLoad %float %val_f
// CHECK-NEXT: [[orig2:%[0-9]+]] = OpAtomicFMaxEXT %float %dest_f %uint_2 %uint_0 [[val4]]
// CHECK-NEXT:                    OpStore %original_f_val [[orig2]]
  InterlockedMax(dest_f, val_f, original_f_val);
}
