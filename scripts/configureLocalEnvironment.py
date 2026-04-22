"""Configure the local sandbox environment for multilingual transpilation.

This script copies the benchmark toolkit from the project's scripts/scripts
directory to /tp_workspace/scripts/scripts and installs all 11 language
runtimes used during reward computation.

Usage:
    cd scripts && python3 configureLocalEnvironment.py
"""

import os
import subprocess
import sys
import time

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Source: the scripts/scripts directory sitting next to this file.
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOCAL_SCRIPTS_DIR = os.path.join(SCRIPT_DIR, "scripts")

TARGET_SCRIPT_PATH = "/tp_workspace/scripts"
TARGET_SCRIPTS_DIR = os.path.join(TARGET_SCRIPT_PATH, "scripts")

BENCH_BIN = "/tp_workspace/scripts/scripts/bin/bench"

LANG_MAP = {
    'c': 'Main.c',
    'cpp': 'Main.cpp',
    'cs': 'Main.cs',
    'go': 'Main.go',
    'hs': 'Main.hs',
    'java': 'Main.java',
    'js': 'Main.js',
    'py': 'Main.py',
    'rb': 'Main.rb',
    'rs': 'Main.rs',
    'pl': 'Main.pl',
}

EXECUTABLE_SCRIPTS = [
    BENCH_BIN,
    "/tp_workspace/scripts/scripts/container.sh",
    "/tp_workspace/scripts/scripts/exec.sh",
    "/tp_workspace/scripts/scripts/gen.sh",
    "/tp_workspace/scripts/scripts/help.sh",
    "/tp_workspace/scripts/scripts/install.sh",
    "/tp_workspace/scripts/scripts/register.sh",
    "/tp_workspace/scripts/scripts/run.sh",
    "/tp_workspace/scripts/scripts/test.sh",
    "/tp_workspace/scripts/scripts/unit_execute.sh",
]

LANGUAGES = ["py", "cpp", "c", "java", "go", "rb", "js", "cs", "rs", "hs", "pl"]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def configure_language_runtime(lang: str) -> None:
    """Install a single language runtime via the bench CLI."""
    subprocess.run(
        f"{BENCH_BIN} install {lang}",
        check=True,
        shell=True,
        executable="/bin/bash",
    )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    start_time = time.time()

    # --- Copy scripts/scripts to the target path ---------------------------
    subprocess.run(["sudo", "mkdir", "-p", TARGET_SCRIPT_PATH], check=True)
    subprocess.run(["sudo", "cp", "-r", LOCAL_SCRIPTS_DIR, TARGET_SCRIPTS_DIR], check=True)

    # --- Make scripts executable ------------------------------------------
    print("Setting up environment...")
    subprocess.run(["sudo", "chmod", "777"] + EXECUTABLE_SCRIPTS, check=True)

    # --- Install all language runtimes ------------------------------------
    for lang in LANGUAGES:
        configure_language_runtime(lang)

    elapsed_time = time.time() - start_time
    print(f"Time elapsed: {elapsed_time:.6f} s.")
    print(f"\u2713 Successfully configured.")


if __name__ == "__main__":
    main()
