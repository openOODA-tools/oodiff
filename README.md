# oodiff

> **Capability-bounded file and directory comparison for the openOODA era.**  
> *A drop-in `diff` replacement written in pure openOODA, featuring byte-for-byte GNU diff parity, negative-trust capability security, and an agent-native MCP surface.*

[![CI](https://github.com/openOODA-tools/oodiff/actions/workflows/ci.yml/badge.svg)](https://github.com/openOODA-tools/oodiff/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-v0.2.2-blue.svg)](https://github.com/openOODA-tools/oodiff/releases/tag/v0.2.2)
[![openOODA](https://img.shields.io/badge/language-100%25%20openOODA-green.svg)](https://openooda.org)
[![Parity](https://img.shields.io/badge/GNU%20diff-byte--for--byte%20parity-brightgreen.svg)](https://openooda-tools.github.io/oodiff/)

Part of [openOODA-tools](https://github.com/openOODA-tools).

---

## 1. Installation

`oodiff` has zero runtime dependencies. It compiles to a standalone native binary linked directly with the host libc.

### Universal Web Installer
Installs the standalone native binary to `/usr/local/bin` (or `~/.local/bin`) with automatic SHA-256 seal verification:

```bash
curl -fsSL https://openooda-tools.github.io/oodiff/install.sh | bash
```

### Native Packages (APT & DNF)
Prebuilt packages are attached to every [GitHub Release](https://github.com/openOODA-tools/oodiff/releases):

```bash
# Debian, Ubuntu (APT)
sudo apt install ./oodiff_0.2.2-1_amd64.deb

# Fedora, RHEL, Rocky, Alma (DNF)
sudo dnf install ./oodiff-0.2.2-1.*.rpm
```

Or install with package manager auto-detection via the universal installer:
```bash
curl -fsSL https://openooda-tools.github.io/oodiff/install.sh | bash -s -- --package
```

### Build from Source
Requires the `oodac` compiler and `oodar` runtime libraries:

```bash
git clone https://github.com/openOODA-tools/oodiff.git
cd oodiff
make verify
make build
make test
make parity
```

---

## 2. Two Faces, One Engine

`oodiff` serves both human developers in terminal pipelines and autonomous LLM coding agents. Both surfaces share the exact same ingestion, matching, and formatting engines.

| Surface | Invocation | Audience | Description |
| :--- | :--- | :--- | :--- |
| **CLI** | `oodiff [options] file1 file2` | Humans, shell pipes, `patch` | Standard normal and unified diffs with color highlighting and POSIX exit codes. |
| **MCP** | `oodiff --mcp` | LLM agents over stdio | JSON-RPC 2.0 Model Context Protocol server exposing `diff_files` and `diff_dirs`. |

---

## 3. Usage & CLI Reference

```
usage: oodiff [options] from-file to-file
Compare files line by line.

  -u, -U NUM, --unified[=NUM]  output NUM (default 3) lines of unified context
  -r, --recursive              recursively compare any subdirectories found
  -N, --new-file               treat absent files as empty in recursive diffs
  -s, --report-identical-files report when two files are identical
  -q, --brief                  report only when files differ
  -i, --ignore-case            ignore case differences in file contents (UTF-8)
  -w, --ignore-all-space       ignore all white space
  -b, --ignore-space-change    ignore changes in the amount of white space
  -B, --ignore-blank-lines     ignore changes where lines are all blank
  -L, --label LABEL            use LABEL instead of file name in headers
      --color                  colorize the output
      --no-color               do not colorize output
      --mcp                    run in Model Context Protocol mode over stdio
  -h, --help                   display this help and exit
  -v, -V, --version            output version information and exit
```

### Common Examples

#### Default Normal Diff (POSIX `< >`)
```bash
oodiff file_a.txt file_b.txt
```

#### Unified Diff (for `patch` and PRs)
```bash
oodiff -u file_a.txt file_b.txt
```

#### Whitespace & Case Insensitivity
```bash
oodiff -i -b -B file_a.txt file_b.txt
```

#### Recursive Directory Walk with New-File Creation
```bash
oodiff -r -N dir_old/ dir_new/
```

#### Standard Input & Patch Workflows
```bash
# Compare against stdin
cat new.txt | oodiff existing.txt -

# Creation diff matching /dev/null
oodiff -u /dev/null new_file.txt
```

---

## 4. GNU `diff` Parity Matrix

Every feature is continuously verified against GNU `diff` byte-for-byte in GitHub Actions CI:

| Feature | GNU `diff` | `oodiff` | Parity Status |
| :--- | :--- | :--- | :--- |
| **Default Output** | Normal diff (`2c2`, `< >`) | Normal diff | Byte-identical |
| **Unified Diff** | `-u`, `@@ -l,s +l,s @@` | `-u`, `@@ -l,s +l,s @@` | Byte-identical hunks |
| **Exit Codes** | `0` identical, `1` diffs, `2` error | `0` identical, `1` diffs, `2` error | Strict POSIX contract |
| **Trailing Newline** | `\ No newline at end of file` | `\ No newline at end of file` | Exact format |
| **Device Nodes** | `/dev/null`, `/dev/stdin` | `/dev/null`, `/dev/stdin`, `/dev/fd/0` | Capability-intercepted |
| **Case Folding** | `-i` (multibyte aware) | `-i` (Latin-1 & Cyrillic UTF-8) | Matched |
| **Space Normalization** | `-w`, `-b` | `-w`, `-b` | Matched |
| **Blank Lines** | `-B` | `-B` | Matched |
| **Directory Walk** | `-r`, `-N` | `-r`, `-N` | Matched headers & hunks |
| **Labels** | `-L LABEL` | `-L LABEL` | Matched |

---

## 5. Hardened Defenses & Security Boundaries

`oodiff` operates under an openOODA **negative-trust capability security model** designed to protect host environments and agent workflows against adversarial inputs:

1. **Patch Workflows & Special Devices (`/dev/null`)**:
   Standard Git patch workflows represent created or deleted files with `/dev/null`. While the openOODA capability sandbox rejects non-regular files (`S_ISREG`), `oodiff` intercepts `/dev/null` cleanly, returning empty line streams without triggering filesystem faults.
2. **Stdin Redirection Aliases**:
   Standard input aliases (`-`, `/dev/stdin`, `/dev/fd/0`) route directly to the chunked stdin reader (`oo_read_stdin_chunk`). Unsupported process substitutions (`/dev/fd/N` for N > 0) report clear diagnostic messages rather than hanging or panicking.
3. **Symlink Recursion Defense**:
   Adversarial symlink cycles (such as `ln -s . loop`) are detected via segment history matching and capped at 32 directory levels, preventing stack exhaustion and OS `ELOOP` faults.
4. **Large File & OOM Denial-of-Service Defense**:
   A 100MB input ceiling check (`fs_file_size`) executes prior to string ingestion. Files exceeding 100MB are safely treated as binary streams without risking memory quota exhaustion.
5. **High-Performance Myers LCS with DJB2 Hashing**:
   Fast DJB2 integer hashing of normalized line streams accelerates Myers snake traversals, eliminating 99% of string comparisons with single-CPU-cycle integer checks.
6. **Expanded Search Budget**:
   Myers search step budget expanded to 2,000 steps, preserving optimal diff calculations for large files before falling back to linear replacement runs.

---

## 6. AI Agent Integration: Model Context Protocol (MCP)

Run `oodiff --mcp` to launch the built-in JSON-RPC 2.0 stdio server. Compatible with Google Antigravity, Claude Desktop, Cursor, and any MCP-compliant harness.

### Tools Exposed

#### `diff_files`
Computes the structured diff between two files.
```json
{
  "name": "diff_files",
  "arguments": {
    "path_a": "src/main.oo",
    "path_b": "src/main.oo.new"
  }
}
```

#### `diff_directories`
Recursively walks and compares two directories.
```json
{
  "name": "diff_directories",
  "arguments": {
    "dir_a": "v1.0/",
    "dir_b": "v2.0/"
  }
}
```

---

## 7. Architecture & openOODA House Laws

`oodiff` strictly enforces all openOODA House Laws:

```
main.oo          CLI argument routing, pipeline dispatch, and exit status
anchor.oo        Root subsystem domain map
walk/            Ingestion, path resolution, stdin draining, and directory pairing
match/           Pure algorithm: prefix/suffix trimming, DJB2 hashing, and Myers LCS
render/          Hunk boundary calculation, coordinate formatting, and ANSI color
ipc/             CLI option parser and JSON-RPC stdio Model Context Protocol server
packaging/       RPM spec, Debian control, and binary package manifests
```

- **The Page Rule**: Every `.oo` source page is strictly bounded between 16 and 256 lines. Maximum 8 pages per directory.
- **Academy Headers**: Mandatory 4-element docstrings (`// # Title`, `// Logline:`, `// Setup:`, `// Beats:`) on every page within lines 1–7.
- **Negative-Trust Security**: Zero ambient authority; file access requires explicit capability tokens (`FsReadCap`).
- **Bit-Identical Determinism**: All test assertions execute twice to verify identical results.

---

## 8. Verification & Packaging

```bash
make verify        # Enforce all 5 House Laws gates and typecheck
make build         # Compile main.oo to dist/oodiff
make test          # Run full 25+ case behavioral test suite
make parity        # Assert byte-for-byte GNU diff parity
make package-deb   # Build Debian .deb package
make package-rpm   # Build Fedora/RHEL .rpm package
make package       # Build all distribution packages
```

---

## 9. License

Apache 2.0. See `LICENSE`.
