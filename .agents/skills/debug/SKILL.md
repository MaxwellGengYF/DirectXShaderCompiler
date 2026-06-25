---
name: debug
description: >
  Capture symbolic x64 C++ stack traces from Windows EXE crashes using debugger.py.
  Use when: a user wants to debug a native crash, verify PDB symbols are loaded,
  or run the in-repo debugger wrapper.
---

# Debug Skill

Use `debugger.py` to launch a Windows x64 executable, catch unhandled exceptions, and print a symbolic stack trace.

## Usage

```powershell
python debugger.py <path-to-exe> [pdb-search-path] [-- <args>...]
```

- `pdb-search-path`: optional; defaults to the EXE's directory.
- `-- <args>...`: optional arguments forwarded to the target executable.

## Running a test executable

Run a built unit-test executable under the debugger. For example, to debug the SPIR-V unit test `LibTest.SourceCodeWithoutFilePath` in `tools/clang/unittests/SPIRV/CodeGenSpirvTest.cpp`:

```powershell
python debugger.py build/bin/ClangSPIRVTests.exe -- --gtest_filter=LibTest.SourceCodeWithoutFilePath
```

Omit `-- <args>` to run the executable with no arguments.

## Requirements

- Windows x64, Python 3.x (64-bit).
- EXE built with a matching PDB (`/Zi`, `/DEBUG`).

## Real-world examples

Run the debugger on `dxc.exe` with `--help` (normal exit):

```powershell
python debugger.py build/bin/dxc.exe -- --help
```

Catch a C++ exception from dxc reading a nonexistent source file. The debugger prints a symbolic stack trace showing the throw chain (`dxc::IFT_Data` → `dxc::ReadFileIntoBlob` → `DxcContext::Compile` → `dxc::main`):

```powershell
python debugger.py build/bin/dxc.exe -- -T ps_6_0 -E main nonexistent.hlsl
```

Build `dxc.exe` first if it does not exist:

```powershell
python build.py --targets dxc
```

## Common issues

| Symptom | Fix |
|---------|-----|
| `<unknown>` function names | Rebuild with `/DEBUG`; place `.pdb` next to `.exe`. |
| No file:line shown | Compile with `/Zi` and `/DEBUG`. |
| `SymLoadModule64 failed` | Usually harmless for system DLLs. |
