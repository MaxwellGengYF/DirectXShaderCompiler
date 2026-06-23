---
name: project_structure
description: Analyzes and navigates the DirectX Shader Compiler (DXC) project structure. Use when asked about DXC codebase organization, directory purposes, component interactions, data flow, build system, testing infrastructure, or when onboarding new developers to the DXC repository.
---

# DXC Project Structure Skill

DXC is a fork of LLVM 3.7 + Clang, modified to compile HLSL → DXIL (and optionally SPIR-V).

## Decision Tree

When a question involves a specific area, go directly to the relevant section:

| User asks about... | Load |
|---|---|
| Where does HLSL → DXIL compilation happen? | SKILL.md → Architecture Layers below |
| Full directory tree, data flow, glossary, build details, test layout | `references/project_structure.md` |
| What does library X do? Summary of a component area | `references/summaries.md` |
| How does `build.py` work? CMake config? | Activate **build** skill |
| Where is file/class `X`? | Use Grep; then consult Architecture Layers for context |

## Architecture Layers

| Layer | Directories | Key Files |
|-------|-------------|-----------|
| **Frontend** | `tools/clang/lib/{Lex,Parse,AST,Sema,CodeGen,SPIRV}` | `SemaHLSL.cpp` (~18K), `CGHLSLMS.cpp` (~268K), `ParseHLSL.cpp` |
| **High-Level IR** | `lib/HLSL/`, `include/dxc/HLSL/` | `HLModule.cpp`, `DxilGenerationPass.cpp`, `HLOperationLower.cpp` |
| **Low-Level IR (DXIL)** | `lib/DXIL/`, `include/dxc/DXIL/` | `DxilModule.cpp`, `DxilOperations.cpp`, `DxilMetadataHelper.cpp` |
| **LLVM Core** | `lib/IR/`, `lib/Analysis/`, `lib/Transforms/` | `Instruction.cpp`, `Function.cpp`, `PassManager.cpp` |
| **DXIL Infrastructure** | `lib/DxilContainer/`, `lib/DxilValidation/`, `lib/DxilRootSignature/` | `DxilValidation.cpp`, `DxilContainerAssembler.cpp` |
| **Debug / PIX** | `lib/DxilDia/`, `lib/DxilPIXPasses/`, `lib/DxrFallback/` | `DxilDebugInstrumentation.cpp`, `DxilDiaSession.cpp` |
| **Compiler Support** | `lib/DxcSupport/`, `lib/Support/` | `HLSLOptions.cpp`, `WinAdapter.cpp`, `FileIOHelper.cpp` |
| **Tools** | `tools/clang/tools/{dxc,dxcompiler,dxv,dxa,dxopt,dxr,...}` | `dxcmain.cpp`, `dxcompilerobj.cpp`, `dxcapi.cpp` |
| **Build & Test** | `cmake/`, `utils/hct/`, `test/`, `unittests/` | `build.py`, `hctgen.py`, `CMakeLists.txt` |
| **SPIR-V Backend** | `tools/clang/lib/SPIRV/` | `EmitVisitor.cpp`, `SpirvEmitter.cpp` |
| **DXBC Converter** | `projects/dxilconv/` | DXBC → DXIL conversion |

## Data Flow

```
HLSL Source → [Clang Frontend] → AST → [CGHLSLMS] → HLModule (high-level IR)
  → [Lowering Passes] → DxilModule (DXIL IR) → [Container Assembly] → [Validation] → DXIL Container
```

Alternative SPIR-V path: `HLSL → Clang Frontend → AST → [tools/clang/lib/SPIRV/] → SPIR-V Binary`

## Key Concepts

- **HLModule** (`lib/HLSL/HLModule.cpp`): High-level IR attached to `llvm::Module`. Tracks matrices, HL intrinsics, resources before lowering.
- **DxilModule** (`lib/DXIL/DxilModule.cpp`): Canonical low-level DXIL state. Created by `DxilGenerationPass`.
- **OP** (`lib/DXIL/DxilOperations.cpp`): DXIL operation manager (`hlsl::OP`). Manages `dx.op.*` intrinsic tables.
- **DXIL Container**: FourCC `DXBC` header + parts: `DXIL` bitcode, `PSV0` (pipeline validation), `RDAT` (reflection), signatures, debug info.
- **Two-Module System**: HLModule (high-level) → DxilGenerationPass → DxilModule (low-level).

## Common Navigation Tasks

**Find where a concept is implemented:**
- HLSL parsing: `tools/clang/lib/Parse/ParseHLSL.cpp`
- HLSL semantics/type checking: `tools/clang/lib/Sema/SemaHLSL.cpp`
- Code generation from AST: `tools/clang/lib/CodeGen/CGHLSLMS.cpp`
- DXIL intrinsic lowering: `lib/HLSL/HLOperationLower.cpp`
- DXIL validation rules: `lib/DxilValidation/DxilValidation.cpp`
- PIX instrumentation: `lib/DxilPIXPasses/DxilDebugInstrumentation.cpp`

**Find headers for a library:** Headers mirror source paths. `lib/DXIL/` ↔ `include/dxc/DXIL/`.

**Identify DXC vs. upstream LLVM changes:** Look for `// HLSL Change` markers in source.

**Find tests for a feature:**
- HLSL semantic tests: `tools/clang/test/SemaHLSL/`
- DXIL codegen tests: `tools/clang/test/CodeGenDXIL/`
- Driver/CLI tests: `tools/clang/test/DXC/`
- SPIR-V tests: `tools/clang/test/CodeGenSPIRV/`
- Unit tests: `unittests/`

## Reference Files

- `references/project_structure.md` — Full directory tree, data flow diagram, build system, testing, glossary. Load for comprehensive codebase maps.
- `references/summaries.md` — Executive summaries per component area. Load for high-level understanding of a subsystem.
