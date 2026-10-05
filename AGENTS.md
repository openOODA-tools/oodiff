# oodiff: House Laws & Where To Start

Status: **skeleton**. Nothing is implemented. This file is the map.

## 1. What oodiff Is

A diff replacement. Compare two files, or two directory trees, and report the
differences. It must agree with `diff` closely enough to replace it in a script,
which means the exit-code contract matters as much as the output:

| Exit | Meaning |
|---|---|
| 0 | no differences |
| 1 | differences found — **not an error** |
| 2 | trouble: bad usage, unreadable operand |

Losing the 0/1/2 distinction is the most common way a diff replacement breaks a
caller, because `set -e` treats 1 as failure and 2 as a real fault.

## 2. The Four Domains

Work lands in exactly one domain at a time. Each anchor.oo states its contract.

| Domain | Job | Does not do |
|---|---|---|
| `walk/` | operands to aligned line streams | decide what differs |
| `match/` | two streams to an edit script | touch FS or net, or render |
| `render/` | edit script to diff text | decide which differences exist |
| `ipc/` | CLI, MCP stdio, AF_UNIX socket | reimplement matching |

Suggested order: `walk/` and `match/` (pure, testable with no harness), then
`render/`, then `ipc/`.

## 3. The Page Rule

Every `.oo` and `.oot` page is 16 to 256 lines. A shim — a file whose every
non-comment line is an import — skips the 16-line floor but never the ceiling.

At most 8 pages per directory, counting tests. This is the limit that forces a
tool to be split into readable pieces rather than one large file.

Never name a page `util.oo`, `utils.oo`, `helper.oo`, `helpers.oo`,
`common.oo`, `misc.oo`, `shared.oo`, `base.oo`, or `core.oo`. A vague name is a
refusal to decide what the page owns. Use a verb: `read_lines.oo`,
`match_common_prefix.oo`.

Imports are relative string literals. There are no `::` namespaces.

## 4. The 4-Element Academy Header

Mandatory on every page, all four elements within the first 7 lines. The gate
enforces this, so a Setup paragraph that runs long will push `Beats:` out and
fail the build.

## 5. Capability Discipline

Zero ambient authority. Every function that touches the outside world takes the
explicit token it needs: `FsReadCap`, `FsWriteCap`, `BindCap`, `ProcessCap`.

Never `/bin/sh -c`. Use an explicit argv array. No shell, no PATH lookup.

Every file descriptor is opened `O_CLOEXEC`.

Validation is negative-trust and fails closed. Double-run determinism is
required: two runs over identical input must produce identical bytes, or a diff
of a diff is noise.

`process_exit` is classified under `ProcessCap`. `main`'s return value does NOT
set exit status, so a non-zero status must be raised explicitly.

## 6. Runtime Traps Already Found

- `str_index_of` returns **byte** offsets while `str_slice` and `char_at` are
  **character** indexed. Mixing them truncates silently on non-ASCII input. Use
  `byte_get` and `byte_sub` together, or nothing.
- `char_at` is O(index); character-by-character scanning is quadratic.
- `byte_concat` cannot lower. `str_concat` fails at check. Use `+`.
- `std/core/primitives/json.oo` `stringify` is identity — no JSON encoder exists.
- `parse_int` is a std builtin at arity 1. Avoid the name.
- Trailing newlines are semantically load-bearing here in a way they are not
  elsewhere: a file ending in a newline and one that does not differ by a line.

## 7. Verification Gate

```
make verify
```

Runs `line-cap`, `file-law`, `academy`, `density`, then `oodac check` on every
page. All five must pass. There is no `test` target yet; add one when the
comparison produces observable output.
