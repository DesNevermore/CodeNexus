# Benchmark CLI (`bench`)

The `scripts/scripts/` directory contains a self-contained benchmark CLI for compiling, executing, and evaluating transpiled code across 11 programming languages. The main entry point is:

```
scripts/scripts/bin/bench
```

---

## Quick Start

```bash
# 1. Register the `bench` command in your shell (optional but convenient):
eval "$(./scripts/scripts/bin/bench register --stdout)"

# 2. Install all language runtimes:
bench install

# 3. Run a source file against test cases:
bench run /path/to/Main.py /path/to/test/
```

If you skip step 1, invoke the CLI with its full path:

```bash
./scripts/scripts/bin/bench <command> [args...]
```

---

## Commands

| Command     | Description                                                        |
| ----------- | ------------------------------------------------------------------ |
| `test`      | Compile a source file and evaluate it against a set of test cases  |
| `run`       | Alias for `test`                                                   |
| `exec`      | Compile and execute a source file (stdin/stdout, no test cases)    |
| `gen`       | Generate test cases by running `gentest*.sh` scripts               |
| `install`   | Install compilers / runtimes for all (or selected) languages       |
| `register`  | Register the `bench` command in your shell profile                 |
| `container` | Create a Docker container with all language runtimes installed     |
| `help`      | Show usage information                                             |

Run `bench help <command>` for detailed usage of any command.

---

## Command Details

### `bench test` / `bench run`

Compile a source file, run it against one or more test cases, and compare the output to expected answers.

```bash
# Test a single source file against a directory of test cases:
bench test <source-file> <test-dir> [checker]

# Test an entire benchmark directory (expects src/ and test/ subdirectories):
bench test <benchmark-dir>
```

**Arguments:**

| Argument        | Description                                                                 |
| --------------- | --------------------------------------------------------------------------- |
| `<source-file>` | Path to the source code (e.g., `Main.py`, `Main.cpp`)                      |
| `<test-dir>`    | Directory containing `.in` (input) / `.ans` (expected output) file pairs    |
| `[checker]`     | Optional custom verifier (`.cpp` source using `testlib.h`)                  |

**Environment Variables:**

| Variable           | Default     | Description                                     |
| ------------------ | ----------- | ----------------------------------------------- |
| `TIMEOUT_DURATION` | `10s`       | Maximum wall-clock time per test case            |
| `TIMEOUT_SIGNAL`   | `SIGTERM`   | Signal sent to kill the process on timeout       |

**Exit codes:**

| Code | Meaning               |
| ---- | --------------------- |
| 0    | All tests passed (ok) |
| 13   | Time limit exceeded   |
| 14   | Runtime error         |
| 15   | Compilation error     |

---

### `bench exec`

Compile and execute a source file interactively (reads from stdin, writes to stdout).

```bash
bench exec <source-file>
```

Compiler output is redirected to stderr. This is useful for quick manual testing.

---

### `bench install`

Install language compilers / runtimes into the current environment.

```bash
# Install all supported languages:
bench install

# Install specific languages only:
bench install py cpp java rs
```

The argument values correspond to the file extension names under `scripts/scripts/languages/` (e.g., `py`, `cpp`, `cs`, `go`, `hs`, `java`, `js`, `pl`, `rb`, `rs`).

---

### `bench register`

Register the `bench` command in your shell so it can be invoked from anywhere.

```bash
# Register for the current user (writes to ~/.bashrc or ~/.profile):
bench register

# Register system-wide:
bench register --system

# Print the registration script without writing it:
bench register --stdout

# Temporary registration for the current session:
eval "$(./scripts/scripts/bin/bench register --stdout)"
```

---

### `bench container`

Create and initialize a Docker container with all language runtimes pre-installed.

```bash
bench container [docker-run-options...]
```

**Environment Variables:**

| Variable          | Default                                           | Description                |
| ----------------- | ------------------------------------------------- | -------------------------- |
| `CONTAINER_USER`  | `root`                                            | Username inside container  |
| `DOCKER_IMAGE`    | `mcr.microsoft.com/devcontainers/base:jammy`      | Base Docker image          |

---

### `bench gen`

Generate test cases by discovering and running `gentest*.sh` scripts inside a benchmark directory.

```bash
bench gen <benchmark-dir>
```

---

## Adding a New Language

To add support for a new language, create a shell script in `scripts/scripts/languages/<ext>.sh` that exports three functions:

```bash
install_dependency()   # Install the compiler / runtime
compile_program()      # Compile a source file (no-op for interpreted languages)
execute_program()      # Execute the compiled / interpreted program
```

The file extension (e.g., `kt` for Kotlin) determines how `bench` dispatches source files to the correct language handler.
