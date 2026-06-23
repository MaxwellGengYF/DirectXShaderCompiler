; RUN: opt -dxil-aggressive-opt %s -S | FileCheck %s

; Test that the aggressive fixed-point optimization pass:
; 1. Runs without crashing
; 2. Removes redundant instructions (fadd x,0; fmul x,1; fsub x,0)
; 3. Converges and produces stable output

target datalayout = "e-m:e-p:32:32-i1:32-i8:32-i16:32-i32:32-i64:64-f16:32-f32:32-f64:64-n8:16:32:64"
target triple = "dxil-ms-dx"

; CHECK-LABEL: define void @redundant_ops
; CHECK-NOT: fadd float
; CHECK-NOT: fmul float
; CHECK-NOT: fsub float
; CHECK: ret void
define void @redundant_ops() {
  %a = alloca float
  store float 1.0, float* %a
  %b = load float, float* %a
  %c = fadd float %b, 0.0
  %d = fmul float %c, 1.0
  %e = fsub float %d, 0.0
  store float %e, float* %a
  ret void
}

; CHECK-LABEL: define void @already_clean
; CHECK: ret void
define void @already_clean() {
  ret void
}
