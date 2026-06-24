// Copyright (c) 2024 Google LLC
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef _HLSL_VK_NV_COOPERATIVE_VECTOR_H_
#define _HLSL_VK_NV_COOPERATIVE_VECTOR_H_

#if __SPIRV_MAJOR_VERSION__ == 1 && __SPIRV_MINOR_VERSION__ < 6
#error "CooperativeVector requires a minimum of SPIR-V 1.6"
#endif

#include <vk/spirv.h>

namespace vk {
namespace nv {

// The base cooperative vector class. The template arguments correspond to the
// operands in the OpTypeCooperativeVectorNV instruction.
template <typename ComponentType, uint components>
class CooperativeVector {
  template <class NewComponentType>
  CooperativeVector<NewComponentType, components> cast();

  // Apply OpSNegate or OpFNegate, depending on ComponentType, in an element by
  // element manner.
  CooperativeVector negate();

  // Apply OpIAdd or OpFAdd, depending on ComponentType, in an element by element
  // manner.
  CooperativeVector operator+(CooperativeVector other);

  // Apply OpISub or OpFSub, depending on ComponentType, in an element by element
  // manner.
  CooperativeVector operator-(CooperativeVector other);

  // Apply OpIMul or OpFMul, depending on ComponentType, in an element by element
  // manner.
  CooperativeVector operator*(CooperativeVector other);

  // Apply OpSDiv, OpUDiv or OpFDiv, depending on ComponentType, in an element by
  // element manner.
  CooperativeVector operator/(CooperativeVector other);

  // Apply OpMatrixTimesScalar in an element by element manner.
  CooperativeVector operator*(ComponentType scalar);

  // Load a cooperative vector using OpCooperativeVectorLoadNV from
  // data[index] using the given memory access operands.
  template <uint32_t memoryAccessOperands, class Type>
  static CooperativeVector Load(RWStructuredBuffer<Type> data, uint32_t index);

  // Same as above, but uses MemoryAccessMaskNone for the memory access
  // operands.
  template <class Type>
  static CooperativeVector Load(RWStructuredBuffer<Type> data, uint32_t index) {
    return Load<MemoryAccessMaskNone>(data, index);
  }

  // Load a cooperative vector using OpCooperativeVectorLoadNV from
  // data[index] using the given memory access operands. No additional memory
  // access bits are added since the memory is readonly.
  template <uint32_t memoryAccessOperands, class Type>
  static CooperativeVector Load(StructuredBuffer<Type> data, uint32_t index);

  // Same as above, but uses MemoryAccessMaskNone for the memory access
  // operands.
  template <class Type>
  static CooperativeVector Load(StructuredBuffer<Type> data, uint32_t index) {
    return Load<MemoryAccessMaskNone>(data, index);
  }

  // Store the cooperative vector using OpCooperativeVectorStoreNV to
  // data[index] using the given memory access operands.
  template <uint32_t memoryAccessOperands, class Type>
  void Store(RWStructuredBuffer<Type> data, uint32_t index);

  // Same as above, but uses MemoryAccessMaskNone for the memory access
  // operands.
  template <class Type>
  void Store(RWStructuredBuffer<Type> data, uint32_t index) {
    Store<MemoryAccessMaskNone>(data, index);
  }

  // Load a cooperative vector using OpCooperativeVectorLoadNV from
  // groupshared memory using the given memory access operands.
  //
  // This function uses a SPIR-V pointer because HLSL does not allow groupshared
  // memory object to be passed by reference.
  template <uint32_t memoryAccessOperands, class Type>
  static CooperativeVector Load(WorkgroupSpirvPointer<Type> data);

  // Same as above, but uses MemoryAccessMaskNone for the memory access
  // operands.
  template <class Type>
  static CooperativeVector Load(WorkgroupSpirvPointer<Type> data) {
    return Load<MemoryAccessMaskNone>(data);
  }

  // Store the cooperative vector using OpCooperativeVectorStoreNV to
  // groupshared memory using the given memory access operands.
  //
  // This function uses a SPIR-V pointer because HLSL does not allow groupshared
  // memory object to be passed by reference.
  template <uint32_t memoryAccessOperands, class Type>
  void Store(WorkgroupSpirvPointer<Type> data);

  // Same as above, but uses MemoryAccessMaskNone for the memory access
  // operands.
  template <class Type>
  void Store(WorkgroupSpirvPointer<Type> data) {
    Store<MemoryAccessMaskNone>(data);
  }

  // Constructs a cooperative vector with all values initialized to v.
  static CooperativeVector Splat(ComponentType v);

  // Returns the number of components in the cooperative vector.
  static uint32_t GetLength();

  // Functions to access the elements of the cooperative vector. The index must
  // be less than GetLength().
  void Set(ComponentType value, uint32_t index);
  ComponentType Get(uint32_t index);

  static const bool hasSignedIntegerComponentType =
      (ComponentType(0) - ComponentType(1) < ComponentType(0));

  // clang-format off
  using SpirvVectorType = vk::SpirvOpaqueType<
      /* OpTypeCooperativeVectorNV */ 5288,
      ComponentType,
      vk::integral_constant<uint, components> >;

  [[vk::ext_extension("SPV_NV_cooperative_vector")]]
  [[vk::ext_capability(/* CooperativeVectorNV */ 5394)]]
  SpirvVectorType _vector;
  // clang-format on
};

// Returns the result of OpCooperativeVectorMatrixMulNV: result = matrix * input.
// The cooperative matrix operands are inferred from signedness.
template <typename ResultComponentType, typename InputComponentType,
          uint M, uint K, class BufferType>
CooperativeVector<ResultComponentType, M>
cooperativeVectorMatrixMul(
    CooperativeVector<InputComponentType, K> input,
    uint inputInterpretation,
    BufferType matrix, uint matrixOffset,
    uint matrixInterpretation,
    uint stride, CooperativeVectorMatrixLayout layout,
    bool transpose);

// Returns the result of OpCooperativeVectorMatrixMulAddNV:
// result = matrix * input + bias.
// The cooperative matrix operands are inferred from signedness.
template <typename ResultComponentType, typename InputComponentType,
          uint M, uint K, class BufferType>
CooperativeVector<ResultComponentType, M>
cooperativeVectorMatrixMulAdd(
    CooperativeVector<InputComponentType, K> input,
    uint inputInterpretation,
    BufferType matrix, uint matrixOffset,
    uint matrixInterpretation,
    BufferType bias, uint biasOffset,
    uint biasInterpretation,
    uint stride, CooperativeVectorMatrixLayout layout,
    bool transpose);

// Atomically accumulates v1 * transpose(v2) into buf.
// REQUIRES: CooperativeVectorTrainingNV capability.
template <typename T, uint M, uint N, class BufferType>
void cooperativeVectorOuterProductAccumulate(
    CooperativeVector<T, M> v1,
    CooperativeVector<T, N> v2,
    BufferType buf, uint offset, uint stride,
    CooperativeVectorMatrixLayout layout, uint matrixInterpretation);

// Atomically adds vector components to buf.
// REQUIRES: CooperativeVectorTrainingNV capability.
template <typename T, uint N, class BufferType>
void cooperativeVectorReduceSumAccumulate(
    CooperativeVector<T, N> v,
    BufferType buf, uint offset);

} // namespace nv
} // namespace vk

#include <vk/nv/cooperative_vector.impl>
#endif // _HLSL_VK_NV_COOPERATIVE_VECTOR_H_
