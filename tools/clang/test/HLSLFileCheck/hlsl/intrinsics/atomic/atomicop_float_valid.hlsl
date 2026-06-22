// RUN: %dxc -T cs_6_6 -E main -fcgl -spirv %s | FileCheck %s

groupshared float   resG[256];
RWBuffer<float>     resB;
RWStructuredBuffer<float> resS;

[numthreads(1,1,1)]
void main(uint tid : SV_DispatchThreadID)
{
  float a = (float)tid;
  int b = (int)tid;
  float orig;

  // Verify that InterlockedAdd/Min/Max with float compile successfully to SPIR-V.

  // CHECK: OpCapability AtomicFloat32AddEXT
  // CHECK: OpExtension "SPV_EXT_shader_atomic_float_add"

  // groupshared float
  // CHECK: OpAtomicFAddEXT %float %resG
  InterlockedAdd(resG[0], a);
  InterlockedAdd(resG[0], a, orig);
  InterlockedMin(resG[0], a);
  InterlockedMin(resG[0], a, orig);
  InterlockedMax(resG[0], a);
  InterlockedMax(resG[0], a, orig);

  // RWBuffer<float>
  // CHECK: OpAtomicFAddEXT %float {{%[0-9]+}}
  InterlockedAdd(resB[0], a);
  InterlockedMin(resB[0], a);
  InterlockedMax(resB[0], a);

  // RWStructuredBuffer<float>
  // CHECK: OpAtomicFAddEXT %float {{%[0-9]+}}
  InterlockedAdd(resS[0], a);
  InterlockedMin(resS[0], a);
  InterlockedMax(resS[0], a);

  // int value with float dest (int -> float implicit conversion)
  // CHECK: OpAtomicFAddEXT %float {{%[0-9]+}}
  InterlockedAdd(resG[0], b);
  InterlockedMin(resG[0], b);
  InterlockedMax(resG[0], b);
}
