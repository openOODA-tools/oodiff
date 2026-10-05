# oodiff

> **Capability-bounded file and directory comparison for the openOODA era.**  
> *A drop-in `diff` replacement written in pure openOODA, featuring an agent-native MCP surface.*

Part of [openOODA-tools](https://github.com/openOODA-tools).

---

## 1. Quick Install

Zero runtime dependencies. The binary is pure native, statically linked with host libc.

```bash
curl -fsSL https://openooda-tools.github.io/oodiff/install.sh | bash
```

### Options
```bash
# Preview installation actions without modifying the host
curl -fsSL https://openooda-tools.github.io/oodiff/install.sh | bash -s -- --dry-run

# Uninstall
curl -fsSL https://openooda-tools.github.io/oodiff/install.sh | bash -s -- --uninstall
```

---

## 2. Two Faces, One Engine

`oodiff` serves both human developers in terminal pipelines and autonomous LLM coding agents. Both surfaces share the exact same ingestion, matching, and formatting engines.

| Surface | Invocation | Audience | Description |
| :--- | :--- | :--- | :--- |
| **CLI** | `oodiff [options] file1 file2` | Humans, shell pipes, `patch` | Standard unified diff output with color highlighting and POSIX exit codes. |
| **MCP** | `oodiff --mcp` | LLM agents over stdio | JSON-RPC 2.0 Model Context Protocol server exposing `diff_files` and `diff_dirs`. |

---

## 3. Usage

```
usage: oodiff [options] from-file to-file
Compare files line by line.

  -u, -U NUM, --unified[=NUM]  output NUM (default 3) lines of unified context
  -r, --recursive              recursively compare any subdirectories found
  -q, --brief                  report only when files differ
  -i, --ignore-case            ignore case differences in file contents
  -w, --ignore-all-space       ignore all white space
      --color                  colorize the output
      --no-color               do not colorize output
      --mcp                    run in Model Context Protocol mode over stdio
  -h, --help                   display this help and exit
  -v, -V, --version            output version information and exit
```

### Examples

#### Compare Two Files
```bash
oodiff file_a.txt file_b.txt
```

#### Compare a File against Standard Input
```bash
cat new_code.oo | oodiff existing_code.oo -
```

#### Recursive Directory Comparison
```bash
oodiff -r src_v1/ src_v2/
```

---

## 4. Exit Code Contract

In POSIX pipelines and automated tooling, exit codes are strictly preserved:

| Exit Code | Meaning | Context |
| :--- | :--- | :--- |
| `0` | Files are identical | No differences detected. |
| `1` | Differences found | Standard successful comparison when changes exist (**not an error**). |
| `2` | Trouble / Fault | Missing operands, unreadable files, or invalid arguments. |

---

## 5. Architecture: The Four Domains

The codebase is strictly structured into four isolated domains under openOODA House Laws:

```
main.oo          CLI argument routing, pipeline dispatch, and exit status
anchor.oo        Root subsystem domain map
walk/            Ingestion, path resolution, stdin draining, and directory pairing
match/           Pure algorithm: common prefix/suffix trimming and Myers LCS edit script
render/          Hunk boundary calculation, coordinate formatting, and ANSI color
ipc/             CLI option parser and JSON-RPC stdio Model Context Protocol server
```

---

## 6. Verification & Governance

All code strictly enforces the openOODA House Laws documented in `AGENTS.md`:

- **The Page Rule**: Every `.oo` and `.oot` source page is strictly bounded between 16 and 256 lines. Maximum 8 pages per directory.
- **Academy Headers**: Mandatory 4-element docstrings (`// # Title`, `// Logline:`, `// Setup:`, `// Beats:`) on every page within the first 7 lines.
- **Zero Ambient Authority**: File access requires explicit capability tokens (`FsReadCap`, `ProcessCap`).
- **Trailing Newline Preservation**: Missing terminal newlines are detected and rendered as `\ No newline at end of file`.
- **Double-Run Determinism**: All test assertions execute twice to verify bit-identical output.

### Running Gates and Tests

```bash
make verify      # Enforce line-cap, file-law, academy headers, density, and oodac check
make test        # Run automated end-to-end behavioral test suite
make parity      # Assert byte-for-byte hunk parity against GNU diff -u
```

---

## 7. Licence

See `LICENSE`.
