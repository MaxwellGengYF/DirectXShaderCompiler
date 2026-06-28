---
name: add_op
description: Guide for implementing a new SPIR-V instruction (opcode) in the DXC HLSL frontend and SPIR-V backend. Use when asked to add a new SPIR-V op, Vulkan extension operator, or intrinsic instruction to DXC.
---

# Adding a New SPIR-V Instruction to DXC

This skill describes the generic workflow for adding a new SPIR-V instruction to DXC. It covers three categories:

| Category | Example | Characteristics |
|----------|---------|----------------|
| **Void-returning** | `OpCopyMemory`, `OpStore` | No result `<id>`, just operand `<id>`s |
| **Value-returning** | `OpLoad`, `OpCopyObject` | Has result type + result `<id>` |
| **Complex/multi-operand** | `OpUntypedGroupAsyncCopyKHR` | 7+ operands, optional memory access masks, capabilities/extensions |

## Decision Tree

| Your instruction is... | Go to section |
|---|---|
| A simple op with operands and no result | **Pattern A** — Void-returning |
| An op with a result value | **Pattern B** — Value-returning |
| An op with many operands + optional memory operands | **Pattern C** — Complex multi-operand |
| You only need to expose an existing op to HLSL without custom logic | Consider `[[vk::ext_instruction]]` only (skip if memory operands / void return is needed) |

## Files to Modify (Complete List)

All 12 files in order:

| # | File | Change |
|---|------|--------|
| 1 | `tools/clang/include/clang/SPIRV/SpirvInstruction.h` | Add Kind enum + instruction class |
| 2 | `tools/clang/lib/SPIRV/SpirvInstruction.cpp` | Constructor + `DEFINE_INVOKE_VISITOR_FOR_CLASS` |
| 3 | `tools/clang/include/clang/SPIRV/SpirvVisitor.h` | `DEFINE_VISIT_METHOD` entry |
| 4 | `tools/clang/include/clang/SPIRV/SpirvBuilder.h` | Builder method declaration |
| 5 | `tools/clang/lib/SPIRV/SpirvBuilder.cpp` | Builder method implementation |
| 6 | `tools/clang/lib/SPIRV/SpirvEmitter.h` | Processing function declaration |
| 7 | `tools/clang/lib/SPIRV/SpirvEmitter.cpp` | Processing function + dispatch in `doCallExpr` |
| 8 | `tools/clang/lib/SPIRV/EmitVisitor.h` | `visit()` declaration |
| 9 | `tools/clang/lib/SPIRV/EmitVisitor.cpp` | `visit()` implementation (binary emission) |
| 10 | `tools/clang/lib/SPIRV/CapabilityVisitor.h` | `visit()` declaration |
| 11 | `tools/clang/lib/SPIRV/CapabilityVisitor.cpp` | `visit()` implementation (capabilities/extensions) |
| 12 | `tools/clang/test/CodeGenSPIRV/<name>.hlsl` | New LIT test file |

---

## Step-by-Step Implementation

### Step 1: Kind Enum + Instruction Class (`SpirvInstruction.h`)

**a) Add Kind enum value**

Find the `Kind` enum (~line 95). Add your entry in alphabetical order:

```cpp
    IK_YourOp,                   // OpYourOp
```

**b) Add instruction class**

Model after one of these patterns depending on your op:

**Pattern A — Void-returning (no result type, e.g., OpStore-like):**

```cpp
/// \brief OpYourOp instruction
/// Brief description.
class SpirvYourOp : public SpirvInstruction {
public:
  SpirvYourOp(SourceLocation loc, /*operands...*/,
              /*optional memory access masks*/,
              SourceRange range = {});

  DEFINE_RELEASE_MEMORY_FOR_CLASS(SpirvYourOp)

  static bool classof(const SpirvInstruction *inst) {
    return inst->getKind() == IK_YourOp;
  }

  bool invokeVisitor(Visitor *v) override;

  // Accessors for each operand
  SpirvInstruction *getOperand1() const { return operand1; }
  // ...

  // Optional: memory access mask support
  bool hasMemoryOperands() const { return memoryAccess[0].hasValue(); }
  bool hasTwoMemoryOperands() const { return memoryAccess[1].hasValue(); }
  spv::MemoryAccessMask getMemoryAccess(uint32_t index) const;
  void setAlignment(uint32_t index, uint32_t alignment);
  bool hasAlignment(uint32_t index) const;
  uint32_t getAlignment(uint32_t index) const;

  void replaceOperand(
      llvm::function_ref<SpirvInstruction *(SpirvInstruction *)> remapOp,
      bool inEntryFunctionWrapper) override {
    operand1 = remapOp(operand1);
    // ...
  }

private:
  SpirvInstruction *operand1;
  // ...
  // For dual memory access masks:
  llvm::Optional<spv::MemoryAccessMask> memoryAccess[2];
  llvm::Optional<uint32_t> memoryAlignment[2];
};
```

The constructor passes `QualType()` (empty) to `SpirvInstruction` base:
```cpp
: SpirvInstruction(IK_YourOp, spv::Op::OpYourOp, QualType(), loc, range),
```

**Pattern B — Value-returning (has result type, e.g., OpLoad-like):**

Same as Pattern A but the constructor takes a `QualType resultType` parameter and passes it to the base:
```cpp
: SpirvInstruction(IK_YourOp, spv::Op::OpYourOp, resultType, loc, range),
```

The instruction has a result `<id>` in SPIR-V binary emission.

**Pattern C — Complex multi-operand (e.g., OpUntypedGroupAsyncCopyKHR):**

Same as Pattern B but with many named operand accessors. Store each operand as a separate member for clarity:
```cpp
private:
  SpirvInstruction *executionScope;
  SpirvInstruction *destination;
  SpirvInstruction *source;
  // ...
  llvm::Optional<spv::MemoryAccessMask> destMemoryAccess;
  llvm::Optional<spv::MemoryAccessMask> srcMemoryAccess;
```

---

### Step 2: Constructor + Visitor Registration (`SpirvInstruction.cpp`)

**a) Add `DEFINE_INVOKE_VISITOR_FOR_CLASS`**

Find the block of these macros (~line 85). Add in alphabetical order:

```cpp
DEFINE_INVOKE_VISITOR_FOR_CLASS(SpirvYourOp)
```

**b) Add constructor**

```cpp
// SpirvYourOp
SpirvYourOp::SpirvYourOp(SourceLocation loc, /*operands...*/,
    /*optional masks*/, SourceRange range)
    : SpirvInstruction(IK_YourOp, spv::Op::OpYourOp,
                       /*QualType() for void, resultType for valued*/,
                       loc, range),
      operand1(op1), operand2(op2) /*...*/ {
  // Set memory access masks if applicable
  memoryAccess[0] = mask1;
  memoryAccess[1] = mask2;
}
```

Add `setAlignment()` if the op supports memory access with alignment:
```cpp
void SpirvYourOp::setAlignment(uint32_t index, uint32_t alignment) {
  assert(index < 2 && "Memory access index must be 0 or 1");
  assert(static_cast<uint32_t>(memoryAccess[index].getValue()) &
         static_cast<uint32_t>(spv::MemoryAccessMask::Aligned));
  memoryAlignment[index] = alignment;
}
```

---

### Step 3: Visitor Dispatch (`SpirvVisitor.h`)

Find the `DEFINE_VISIT_METHOD` block (~line 110). Add in alphabetical order:

```cpp
  DEFINE_VISIT_METHOD(SpirvYourOp)
```

This macro adds a virtual `visit(SpirvYourOp*)` method to the base `Visitor` class, which all derived visitors (EmitVisitor, CapabilityVisitor, etc.) override.

---

### Step 4: Builder API (`SpirvBuilder.h` + `SpirvBuilder.cpp`)

**a) Declaration in `SpirvBuilder.h`**

Find existing similar methods (e.g., `createCopyObject`, `createStore`). Add:

```cpp
  /// \brief Creates an OpYourOp instruction.
  /// Brief description of operands.
  void createYourOp(
      /*operands...*/,
      /*optional memory access masks*/,
      SourceLocation loc = {}, SourceRange range = {});

  // For value-returning ops, return the instruction pointer:
  SpirvYourOp *createYourOp(
      QualType resultType, /*operands...*/,
      SourceLocation loc = {}, SourceRange range = {});
```

**b) Implementation in `SpirvBuilder.cpp`**

```cpp
void SpirvBuilder::createYourOp(
    /*operands...*/,
    llvm::Optional<spv::MemoryAccessMask> mask1,
    llvm::Optional<spv::MemoryAccessMask> mask2,
    SourceLocation loc, SourceRange range) {
  assert(insertPoint && "null insert point");
  auto *inst = new (context)
      SpirvYourOp(loc, /*operands...*/, mask1, mask2, range);
  insertPoint->addInstruction(inst);
}

// For value-returning:
SpirvYourOp *SpirvBuilder::createYourOp(
    QualType resultType, /*operands...*/,
    SourceLocation loc, SourceRange range) {
  assert(insertPoint && "null insert point");
  auto *inst = new (context)
      SpirvYourOp(resultType, loc, /*operands...*/, range);
  insertPoint->addInstruction(inst);
  return inst;
}
```

---

### Step 5: Emitter Processing (`SpirvEmitter.h` + `SpirvEmitter.cpp`)

**a) Declare processing function in `SpirvEmitter.h`**

```cpp
  /// Process __builtin_spirv_your_op calls (OpYourOp)
  SpirvInstruction *processIntrinsicYourOp(const CallExpr *callExpr);
```

**b) Declare identification helpers (or use name-based)**

Add forward declarations before `doCallExpr` (~line 3178):

```cpp
static bool isIntrinsicYourOp(const FunctionDecl *FD);
```

Define them later:
```cpp
static bool isIntrinsicYourOp(const FunctionDecl *FD) {
  return FD->getName() == "__builtin_spirv_your_op";
}
```

**c) Add dispatch in `doCallExpr`**

Inside `SpirvEmitter::doCallExpr`, before the `VKInstructionExtAttr` check:

```cpp
    // Check for builtin spirv intrinsics
    if (isIntrinsicYourOp(funcDecl))
      return processIntrinsicYourOp(callExpr);
```

**d) Implement processing function**

For `[[vk::ext_reference]]` parameters (pointer/address operands), follow this pattern:

```cpp
SpirvInstruction *SpirvEmitter::processIntrinsicYourOp(
    const CallExpr *callExpr) {
  const auto args = callExpr->getArgs();
  const SourceLocation loc = callExpr->getExprLoc();
  const SourceRange range = callExpr->getSourceRange();

  // Handle [[vk::ext_reference]] params (must be lvalues)
  auto handleRefParam = [&](uint32_t idx) -> SpirvInstruction * {
    const Expr *arg = args[idx]->IgnoreParenLValueCasts();
    SpirvInstruction *argInst = doExpr(arg);
    if (argInst->isRValue()) {
      emitError("argument for a parameter with vk::ext_reference attribute "
                "must be a reference",
                arg->getExprLoc());
      return nullptr;
    }
    return argInst;
  };

  // Extract reference operands
  SpirvInstruction *operand1 = handleRefParam(0);
  // ...

  // For [[vk::ext_literal]] integer operands:
  if (callExpr->getNumArgs() > N) {
    if (auto *constVal = dyn_cast<SpirvConstantInteger>(
            constEvaluator.tryToEvaluateAsConst(args[N], isSpecConstantMode)))
      // use constVal->getValue().getZExtValue()
  }

  // For value operands (not ref, not literal):
  SpirvInstruction *operand = doExpr(args[N]);

  // Call builder
  spvBuilder.createYourOp(/*operands...*/, loc, range);

  return nullptr; // for void-returning ops
  // -- OR --
  QualType retType = callExpr->getType();
  return spvBuilder.createYourOp(retType, /*operands...*/, loc, range);
}
```

---

### Step 6: Binary Emission (`EmitVisitor.h` + `EmitVisitor.cpp`)

**a) Declare in `EmitVisitor.h`**

```cpp
  bool visit(SpirvYourOp *) override;
```

**b) Implement in `EmitVisitor.cpp`**

**Pattern A — Void-returning op (no result type/id):**

```cpp
bool EmitVisitor::visit(SpirvYourOp *inst) {
  initInstruction(inst);
  // Emit operands (no result type, no result id)
  curInst.push_back(getOrAssignResultId<SpirvInstruction>(inst->getOperand1()));
  curInst.push_back(getOrAssignResultId<SpirvInstruction>(inst->getOperand2()));
  // ...

  // Optional: emit memory access masks
  if (inst->hasMemoryOperands()) {
    spv::MemoryAccessMask mask = inst->getMemoryAccess(0);
    curInst.push_back(static_cast<uint32_t>(mask));
    if (inst->hasAlignment(0)) {
      assert(static_cast<uint32_t>(mask) &
             static_cast<uint32_t>(spv::MemoryAccessMask::Aligned));
      curInst.push_back(inst->getAlignment(0));
    }
  }
  if (inst->hasTwoMemoryOperands()) {
    spv::MemoryAccessMask mask = inst->getMemoryAccess(1);
    curInst.push_back(static_cast<uint32_t>(mask));
    if (inst->hasAlignment(1)) {
      assert(static_cast<uint32_t>(mask) &
             static_cast<uint32_t>(spv::MemoryAccessMask::Aligned));
      curInst.push_back(inst->getAlignment(1));
    }
  }

  finalizeInstruction(&mainBinary);
  return true;
}
```

**Pattern B — Value-returning op (has result type/id):**

```cpp
bool EmitVisitor::visit(SpirvYourOp *inst) {
  initInstruction(inst);
  curInst.push_back(inst->getResultTypeId());
  curInst.push_back(getOrAssignResultId<SpirvInstruction>(inst));
  // Emit remaining operands...
  curInst.push_back(getOrAssignResultId<SpirvInstruction>(inst->getOperand1()));
  // ...
  finalizeInstruction(&mainBinary);
  emitDebugNameForInstruction(getOrAssignResultId<SpirvInstruction>(inst),
                              inst->getDebugName());
  return true;
}
```

---

### Step 7: Capabilities and Extensions (`CapabilityVisitor.h` + `CapabilityVisitor.cpp`)

**a) Declare in `CapabilityVisitor.h`**

```cpp
  bool visit(SpirvYourOp *) override;
```

**b) Implement in `CapabilityVisitor.cpp`**

Determine what capabilities/extensions your op requires from the SPIR-V spec:

```cpp
bool CapabilityVisitor::visit(SpirvYourOp *inst) {
  // If the op is core with no capabilities needed:
  // return true;

  // If the op requires a capability:
  addCapability(spv::Capability::YourCapability, inst->getSourceLocation());
  
  // If the op requires an extension (check Extension enum in FeatureManager.h):
  // addExtension(Extension::YOUR_extension, "SpirvYourOp",
  //              inst->getSourceLocation());
  
  return true;
}
```

Check existing extensions in `tools/clang/include/clang/SPIRV/FeatureManager.h` (`enum class Extension`). If your extension isn't listed, add it there first.

---

### Step 8: HLSL Frontend API Design

The HLSL API uses `[[vk::ext_instruction(opcode, "")]]` attribute functions:

```hlsl
// Void-returning op example:
[[vk::ext_instruction(OPCODE, "")]]
void __builtin_spirv_your_op(
    [[vk::ext_reference]] inout TargetType target,
    [[vk::ext_reference]] in SourceType source
);

// With literal parameters:
[[vk::ext_instruction(OPCODE, "")]]
void __builtin_spirv_your_op(
    [[vk::ext_reference]] inout TargetType target,
    [[vk::ext_reference]] in SourceType source,
    [[vk::ext_literal]] uint mask
);

// Value-returning op example:
[[vk::ext_instruction(OPCODE, "")]]
ReturnType __builtin_spirv_your_op(
    [[vk::ext_reference]] in SourceType source
);

// With capabilities/extensions on the declaration:
[[vk::ext_instruction(OPCODE, "")]]
[[vk::ext_capability(CAPABILITY_VALUE)]]
[[vk::ext_extension("EXTENSION_NAME")]]
ReturnType __builtin_spirv_your_op(...);
```

**Important:** The built-in `processSpvIntrinsicCallExpr` handles `[[vk::ext_capability]]` and `[[vk::ext_extension]]` attributes automatically. If you use custom processing (Step 5), those attributes on the function declaration are **bypassed** — you must add capabilities/extensions explicitly in `CapabilityVisitor` (Step 7).

Requires `-HV 202x` flag for `[[vk::ext_*]]` attribute support.

---

### Step 9: Testing

Create `tools/clang/test/CodeGenSPIRV/<your-op>.hlsl`:

```hlsl
// RUN: %dxc -T cs_6_0 -E main -spirv -HV 202x -Od %s | FileCheck %s

[[vk::ext_instruction(OPCODE, "")]]
void __builtin_spirv_your_op([[vk::ext_reference]] inout int target,
                              [[vk::ext_reference]] in int source);

[numthreads(1, 1, 1)]
void main() {
    int a = 42;
    int b;
    // CHECK: OpYourOp %b %a
    __builtin_spirv_your_op(b, a);
}
```

Test variations:
- **Local → Local**: Function storage class pointers
- **groupshared → Local**: Workgroup → Function storage classes
- **Local → groupshared**: Function → Workgroup storage classes
- **groupshared → groupshared**: Same Workgroup storage class
- **Buffer element → Local**: StorageBuffer/Uniform → Function
- **Cross storage-class**: e.g., Workgroup → StorageBuffer
- **With memory operands**: Use `[[vk::ext_literal]]` parameters
- **Dynamic indexing**: Use `SV_GroupIndex` or similar variable index

Run verification:
```bash
build/bin/dxc.exe -T cs_6_0 -E main -spirv -HV 202x -Od <test_file>
```

---

## Common Pitfalls

| Issue | Symptom | Fix |
|-------|---------|-----|
| `SpirvConstant::getValue()` doesn't exist | Compile error C2039 | Use `dyn_cast<SpirvConstantInteger>(constVal)->getValue()` |
| Visitor base has no `visit(YourOp*)` | Compiler can't dispatch | Add `DEFINE_VISIT_METHOD(SpirvYourOp)` in `SpirvVisitor.h` |
| `OpCopyMemory` source not a pointer | Validation error: "Source operand is not a pointer" | Use `[[vk::ext_reference]]` and `handleRefParam` to get pointer, not value |
| Extension enum missing | `Extension::YOUR_EXT` not found | Add to `enum class Extension` in `FeatureManager.h` |
| SPIR-V 1.4+ dual masks cause validation error | "expected more operands" | When `Aligned` flag is set, emit alignment word after the mask |
| HLSL `void` parameter not allowed | "'void' must be the first and only parameter" | Use concrete types instead of `void` or use templates |
