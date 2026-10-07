# oodiff v0.0.1 Makefile
#
# Skeleton. Build and the verification gate only; there is no behaviour to test
# yet, so there is no test target. Add one when the filter lands.
#
# Usage:
#   make build       - compile main.oo to dist/oodiff
#   make check       - run oodac check on every .oo file
#   make line-cap    - enforce 16-256 line cap on every .oo and .oot (shim-exempt)
#   make file-law    - reject forbidden file extensions and stray docs
#   make academy     - verify every .oo has the 4-element Academy header
#   make density     - enforce at most 8 pages per directory
#   make verify      - run line-cap, file-law, academy, density, and check
#   make clean       - remove build artifacts

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/oodiff

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)

.PHONY: build check line-cap file-law academy density verify clean test parity package package-deb package-rpm package-arch install uninstall

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@echo "built $(BIN)"

# --- Verification gate ---------------------------------------------------------

# A shim is a file whose every non-comment line is an import. Shims skip the
# 16-line floor. The 256-line ceiling still applies to them without exception.
line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
			continue; \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="py js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		$(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

test: $(BIN)
	@echo "=== testing --help ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@echo "=== testing --version ==="
	@./$(BIN) --version > /dev/null && echo "PASS: --version"
	@echo "=== testing missing operand (expect 2) ==="
	@./$(BIN) > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: missing operand exits 2"
	@echo "=== testing extra operand (expect 2) ==="
	@./$(BIN) a b c > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: extra operand exits 2"
	@echo "=== testing missing file (expect 2) ==="
	@./$(BIN) qa/fixtures/test_a.txt qa/fixtures/nonexistent.txt > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: nonexistent file exits 2"
	@echo "=== testing identical files (expect 0) ==="
	@./$(BIN) qa/fixtures/test_a.txt qa/fixtures/test_a.txt > /dev/null && echo "PASS: identical files exit 0"
	@echo "=== testing report-identical -s ==="
	@./$(BIN) -s qa/fixtures/test_a.txt qa/fixtures/test_a.txt | grep -q "identical" && echo "PASS: -s reports identical"
	@echo "=== testing single file normal diff ==="
	@./$(BIN) --no-color qa/fixtures/test_a.txt qa/fixtures/test_b.txt | grep -q "2c2" && echo "PASS: normal diff default"
	@echo "=== testing single file unified diff ==="
	@./$(BIN) -u --no-color qa/fixtures/test_a.txt qa/fixtures/test_b.txt | grep -q -- "-banana" && echo "PASS: unified diff contains deletion"
	@./$(BIN) -u --no-color qa/fixtures/test_a.txt qa/fixtures/test_b.txt | grep -q -- "+orange" && echo "PASS: unified diff contains addition"
	@echo "=== testing case insensitivity -i ==="
	@./$(BIN) -i qa/fixtures/case_a.txt qa/fixtures/case_b.txt && echo "PASS: -i ignores case"
	@echo "=== testing ignore all space -w ==="
	@./$(BIN) -w qa/fixtures/sp_a.txt qa/fixtures/sp_b.txt && echo "PASS: -w ignores all space"
	@echo "=== testing ignore space change -b ==="
	@./$(BIN) -b qa/fixtures/bsp_a.txt qa/fixtures/bsp_b.txt && echo "PASS: -b ignores space change"
	@echo "=== testing ignore blank lines -B ==="
	@./$(BIN) -B qa/fixtures/blk_a.txt qa/fixtures/blk_b.txt && echo "PASS: -B ignores blank lines"
	@echo "=== testing stdin pipe ==="
	@printf "apple\npear\n" | ./$(BIN) -u --no-color qa/fixtures/test_a.txt - | grep -q -- "+pear" && echo "PASS: stdin diff works"
	@echo "=== testing trailing newline diagnostic ==="
	@./$(BIN) --no-color qa/fixtures/no_nl.txt qa/fixtures/with_nl.txt | grep -q "No newline at end of file" && echo "PASS: newline diagnostic present"
	@echo "=== testing label -L ==="
	@./$(BIN) -u -L "FOO" -L "BAR" qa/fixtures/test_a.txt qa/fixtures/test_b.txt | grep -q -- "--- FOO" && echo "PASS: -L sets labels"
	@echo "=== testing brief mode ==="
	@./$(BIN) -q qa/fixtures/test_a.txt qa/fixtures/test_b.txt | grep -q "differ" && echo "PASS: brief mode reports differ"
	@echo "=== testing recursive directory walk ==="
	@./$(BIN) --no-color -r qa/fixtures/dir_a qa/fixtures/dir_b | grep -q "Only in qa/fixtures/dir_a: del.txt" && echo "PASS: directory walk reports Only in"
	@echo "=== testing recursive directory new-file -N ==="
	@./$(BIN) --no-color -r -N qa/fixtures/dir_a qa/fixtures/dir_b | grep -q "diff -r -N" && echo "PASS: directory walk handles -N"
	@echo "=== testing MCP stdio initialize ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "protocolVersion" && echo "PASS: MCP initialize"
	@echo "=== testing MCP stdio tools/list ==="
	@printf '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "diff_files" && echo "PASS: MCP tools/list"
	@echo "=== testing MCP stdio tools/call ==="
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"diff_files","arguments":{"path_a":"qa/fixtures/test_a.txt","path_b":"qa/fixtures/test_b.txt"}}}\n' | ./$(BIN) --mcp | grep -q "content" && echo "PASS: MCP tools/call"
	@echo "=== testing /dev/null creation ==="
	@./$(BIN) -u /dev/null qa/fixtures/test_a.txt | grep -q -- "@@ -0,0 +1,3 @@" && echo "PASS: /dev/null creation diff"
	@echo "=== testing symlink cycle defense ==="
	@mkdir -p .ooda-cache/sym_test && ln -sf . .ooda-cache/sym_test/loop 2>/dev/null || true; \
	./$(BIN) -r .ooda-cache/sym_test qa/fixtures/dir_b | grep -q "Only in .ooda-cache/sym_test: loop" && echo "PASS: symlink cycle pruned"
	@echo "=== testing UTF-8 case folding -i ==="
	@./$(BIN) -i qa/fixtures/utf_a.txt qa/fixtures/utf_b.txt && echo "PASS: -i UTF-8 case folding"
	@echo "=== testing stdin aliases (/dev/stdin, /dev/fd/0) ==="
	@printf "apple\nbanana\ncherry\n" | ./$(BIN) /dev/stdin qa/fixtures/test_a.txt > /dev/null && echo "PASS: /dev/stdin alias"
	@printf "apple\nbanana\ncherry\n" | ./$(BIN) /dev/fd/0 qa/fixtures/test_a.txt > /dev/null && echo "PASS: /dev/fd/0 alias"
	@echo "=== testing process substitution /dev/fd/N diagnostic ==="
	@./$(BIN) /dev/fd/3 qa/fixtures/test_a.txt 2>&1 | grep -q "file descriptor redirection not supported" && echo "PASS: /dev/fd/N diagnostic"
	@echo "=== testing double-run determinism ==="
	@./$(BIN) --no-color qa/fixtures/test_a.txt qa/fixtures/test_b.txt > .ooda-cache/run1.txt 2>&1 || true; \
	./$(BIN) --no-color qa/fixtures/test_a.txt qa/fixtures/test_b.txt > .ooda-cache/run2.txt 2>&1 || true; \
	cmp .ooda-cache/run1.txt .ooda-cache/run2.txt && echo "PASS: double-run output is bit-identical"
	@echo "ALL TESTS PASSED"

parity: $(BIN)
	@echo "=== verifying normal diff parity ==="
	@diff qa/fixtures/test_a.txt qa/fixtures/test_b.txt > .ooda-cache/exp_norm.txt || true; \
	./$(BIN) --no-color qa/fixtures/test_a.txt qa/fixtures/test_b.txt > .ooda-cache/act_norm.txt || true; \
	diff -u .ooda-cache/exp_norm.txt .ooda-cache/act_norm.txt && echo "PASS: normal diff matches diff byte-for-byte"
	@echo "=== verifying unified diff parity ==="
	@diff -u qa/fixtures/test_a.txt qa/fixtures/test_b.txt | tail -n +3 > .ooda-cache/diff_expected.txt || true; \
	./$(BIN) -u --no-color qa/fixtures/test_a.txt qa/fixtures/test_b.txt | tail -n +3 > .ooda-cache/diff_actual.txt || true; \
	diff -u .ooda-cache/diff_expected.txt .ooda-cache/diff_actual.txt && echo "PASS: hunks match diff -u byte-for-byte"
	@echo "=== verifying /dev/null parity ==="
	@diff -u /dev/null qa/fixtures/test_a.txt | tail -n +3 > .ooda-cache/exp_null.txt || true; \
	./$(BIN) -u /dev/null qa/fixtures/test_a.txt | tail -n +3 > .ooda-cache/act_null.txt || true; \
	diff -u .ooda-cache/exp_null.txt .ooda-cache/act_null.txt && echo "PASS: /dev/null matches diff -u byte-for-byte"
	@echo "=== verifying recursive directory parity ==="
	@diff -r qa/fixtures/dir_a qa/fixtures/dir_b > .ooda-cache/exp_rec.txt || true; \
	./$(BIN) --no-color -r qa/fixtures/dir_a qa/fixtures/dir_b > .ooda-cache/act_rec.txt || true; \
	diff -u .ooda-cache/exp_rec.txt .ooda-cache/act_rec.txt && echo "PASS: recursive diff matches diff -r byte-for-byte"
	@echo "=== verifying recursive new-file parity ==="
	@diff -r -N qa/fixtures/dir_a qa/fixtures/dir_b > .ooda-cache/exp_rec_n.txt || true; \
	./$(BIN) --no-color -r -N qa/fixtures/dir_a qa/fixtures/dir_b > .ooda-cache/act_rec_n.txt || true; \
	diff -u .ooda-cache/exp_rec_n.txt .ooda-cache/act_rec_n.txt && echo "PASS: recursive -r -N matches diff -r -N byte-for-byte"
	@echo "=== verifying ignore-blank-lines -B parity ==="
	@diff -B qa/fixtures/blk_x.txt qa/fixtures/blk_y.txt > .ooda-cache/exp_blk.txt || true; \
	./$(BIN) --no-color -B qa/fixtures/blk_x.txt qa/fixtures/blk_y.txt > .ooda-cache/act_blk.txt || true; \
	diff -u .ooda-cache/exp_blk.txt .ooda-cache/act_blk.txt && echo "PASS: -B matches diff -B byte-for-byte"
	@echo "ALL PARITY CHECKS PASSED"

VERSION ?= 0.3.1

install: $(BIN)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/oodiff
	install -m 0755 uninstall.sh $(DESTDIR)$(BINDIR)/oodiff-uninstall
	@echo "installed oodiff and oodiff-uninstall to $(DESTDIR)$(BINDIR)"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/oodiff $(DESTDIR)$(BINDIR)/oodiff-uninstall
	@if [ "$(PURGE)" = "1" ]; then rm -rf $(HOME)/.cache/oodiff $(HOME)/.config/oodiff; echo "purged user cache and config"; fi
	@echo "uninstalled oodiff and oodiff-uninstall from $(DESTDIR)$(BINDIR)"

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/oodiff
	@chmod 0755 dist/deb-root/usr/bin/oodiff
	@cp uninstall.sh dist/deb-root/usr/bin/oodiff-uninstall
	@chmod 0755 dist/deb-root/usr/bin/oodiff-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/oodiff_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/oodiff_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/oodiff-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/oodiff.spec > ~/rpmbuild/SPECS/oodiff.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/oodiff.spec
	@cp ~/rpmbuild/RPMS/x86_64/oodiff-$(VERSION)*.rpm dist/
	@echo "built dist RPM package"

package-arch:
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "validated packaging/arch/PKGBUILD and packaging/PKGBUILD"

package: package-deb package-rpm package-arch

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
