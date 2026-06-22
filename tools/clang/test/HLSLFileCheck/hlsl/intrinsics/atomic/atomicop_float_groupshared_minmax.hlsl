// RUN: %dxc -T cs_6_6 -E main %s | FileCheck %s

groupshared float dest_f;

[numthreads(1,1,1)]
void main(uint tid : SV_DispatchThreadID)
{
  float original_f_val;
  float val_f = (float)tid;

  // Float InterlockedMin should use bitcast to i32 and atomicrmw min on i32.
  // CHECK: %[[val:.*]] = load float, float* {{%[0-9]+}}
  // CHECK-NEXT: %[[val_int:.*]] = bitcast float %[[val]] to i32
  // CHECK-NEXT: %[[dest_int:.*]] = bitcast float addrspace(3)* @dest_f to i32 addrspace(3)*
  // CHECK-NEXT: %[[old:.*]] = atomicrmw min i32 addrspace(3)* %[[dest_int]], i32 %[[val_int]] seq_cst
  InterlockedMin(dest_f, val_f);

  // Float InterlockedMin with original output
  // CHECK: %[[val2:.*]] = load float, float* {{%[0-9]+}}
  // CHECK-NEXT: %[[val_int2:.*]] = bitcast float %[[val2]] to i32
  // CHECK-NEXT: %[[dest_int2:.*]] = bitcast float addrspace(3)* @dest_f to i32 addrspace(3)*
  // CHECK-NEXT: %[[old2:.*]] = atomicrmw min i32 addrspace(3)* %[[dest_int2]], i32 %[[val_int2]] seq_cst
  // CHECK-NEXT: %[[result2:.*]] = bitcast i32 %[[old2]] to float
  // CHECK-NEXT: store float %[[result2]], float* {{%[0-9]+}}
  InterlockedMin(dest_f, val_f, original_f_val);

  // Float InterlockedMax
  // CHECK: %[[val3:.*]] = load float, float* {{%[0-9]+}}
  // CHECK-NEXT: %[[val_int3:.*]] = bitcast float %[[val3]] to i32
  // CHECK-NEXT: %[[dest_int3:.*]] = bitcast float addrspace(3)* @dest_f to i32 addrspace(3)*
  // CHECK-NEXT: %[[old3:.*]] = atomicrmw max i32 addrspace(3)* %[[dest_int3]], i32 %[[val_int3]] seq_cst
  InterlockedMax(dest_f, val_f);

  // Float InterlockedMax with original output
  // CHECK: %[[val4:.*]] = load float, float* {{%[0-9]+}}
  // CHECK-NEXT: %[[val_int4:.*]] = bitcast float %[[val4]] to i32
  // CHECK-NEXT: %[[dest_int4:.*]] = bitcast float addrspace(3)* @dest_f to i32 addrspace(3)*
  // CHECK-NEXT: %[[old4:.*]] = atomicrmw max i32 addrspace(3)* %[[dest_int4]], i32 %[[val_int4]] seq_cst
  // CHECK-NEXT: %[[result4:.*]] = bitcast i32 %[[old4]] to float
  // CHECK-NEXT: store float %[[result4]], float* {{%[0-9]+}}
  InterlockedMax(dest_f, val_f, original_f_val);
}
