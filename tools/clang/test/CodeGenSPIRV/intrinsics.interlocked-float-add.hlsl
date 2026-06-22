// RUN: %dxc -T cs_6_6 -E main -fcgl %s -spirv | FileCheck %s

groupshared float dest_f;
RWBuffer<float> buff_f;
RWStructuredBuffer<float> sbuff_f;

[numthreads(1,1,1)]
void main()
{
  float original_f_val;
  float val_f;

// CHECK: OpCapability AtomicFloat32AddEXT
// CHECK: OpExtension "SPV_EXT_shader_atomic_float_add"

  // Test InterlockedAdd on groupshared float
// CHECK:      [[val:%[0-9]+]] = OpLoad %float %val_f
// CHECK-NEXT:  {{%[0-9]+}} = OpAtomicFAddEXT %float %dest_f %uint_2 %uint_0 [[val]]
  InterlockedAdd(dest_f, val_f);

  // Test InterlockedAdd on groupshared float with output original value
// CHECK:      [[val2:%[0-9]+]] = OpLoad %float %val_f
// CHECK-NEXT: [[orig:%[0-9]+]] = OpAtomicFAddEXT %float %dest_f %uint_2 %uint_0 [[val2]]
// CHECK-NEXT:                   OpStore %original_f_val [[orig]]
  InterlockedAdd(dest_f, val_f, original_f_val);

  // Test InterlockedAdd on RWBuffer<float>
// CHECK:      [[bufptr:%[0-9]+]] = OpImageTexelPointer %_ptr_Image_float %buff_f %uint_0 %uint_0
// CHECK-NEXT: [[val3:%[0-9]+]] = OpLoad %float %val_f
// CHECK-NEXT:  {{%[0-9]+}} = OpAtomicFAddEXT %float [[bufptr]] %uint_1 %uint_0 [[val3]]
  InterlockedAdd(buff_f[0], val_f);

  // Test InterlockedAdd on RWStructuredBuffer<float>
// CHECK:      [[ac:%[0-9]+]] = OpAccessChain %_ptr_Uniform_float %sbuff_f %uint_0 %uint_0
// CHECK-NEXT: [[val4:%[0-9]+]] = OpLoad %float %val_f
// CHECK-NEXT:  {{%[0-9]+}} = OpAtomicFAddEXT %float [[ac]] %uint_1 %uint_0 [[val4]]
  InterlockedAdd(sbuff_f[0], val_f);
}
