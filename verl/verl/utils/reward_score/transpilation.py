"""Reward functions for multilingual transpilation training with GRPO.

This module provides three reward components:
  1. **Format reward** -- checks that the response follows the
     ``<think>...</think><answer>...</answer>`` structure.
  2. **Code-format reward** -- additionally verifies the presence of a
     fenced code block in the correct target language.
  3. **Execution reward** -- compiles and runs the generated code inside
     a sandbox, comparing outputs against reference test cases.

The final composite score is computed by :func:`compute_score` which
combines an *aggressive* transformation of the execution pass rate with
the two format rewards.
"""

import json
import logging
import re
import subprocess
import threading
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)

fileLock = threading.Lock()

# ---------------------------------------------------------------------------
# Language extension mapping
# ---------------------------------------------------------------------------

LANGUAGE_TO_SUFFIX: Dict[str, str] = {
    "python": "py",
    "c": "c",
    "csharp": "cs",
    "cpp": "cpp",
    "java": "java",
    "javascript": "js",
    "go": "go",
    "ruby": "rb",
    "rust": "rs",
    "haskell": "hs",
    "perl": "pl",
}

# ---------------------------------------------------------------------------
# Format rewards
# ---------------------------------------------------------------------------


def format_reward(completion: str, **kwargs: Any) -> float:
    """Check that the response wraps reasoning in ``<think>`` and the answer in ``<answer>``."""
    pattern = r"^<think>\n.*?\n</think>\n<answer>\n.*?\n</answer>$"
    return 1.0 if re.match(pattern, completion, re.DOTALL | re.MULTILINE) else 0.0


def get_code_format_reward(completion: str, language: str = "python", **kwargs: Any) -> float:
    """Check format *and* the presence of a fenced code block for *language*."""
    match = re.match(
        rf"^<think>\n.*?\n</think>\n<answer>\n.*?```{language}.*?```.*?\n</answer>$",
        completion,
        re.DOTALL | re.MULTILINE,
    )
    return 1.0 if match else 0.0


# ---------------------------------------------------------------------------
# Code extraction
# ---------------------------------------------------------------------------


def extract_code(completion: str, language: Optional[str] = "python") -> str:
    """Extract the last fenced code block for *language* from *completion*."""
    if language is None:
        return ""
    pattern = re.compile(rf"```{language}\n(.*?)```", re.DOTALL)
    matches = pattern.findall(completion)
    return matches[-1] if len(matches) >= 1 else ""


# ---------------------------------------------------------------------------
# Sandbox execution reward
# ---------------------------------------------------------------------------

# Template executed *inside* the sandbox to compute the pass rate.
_EXECUTION_SCRIPT_TEMPLATE = """import subprocess
import json
import psutil
import sys
import json
import tempfile
import shutil
import pandas as pd
import os

def kill_process_and_all_descendants(pid):
    try:
        # Get the process object for the given PID
        process = psutil.Process(pid)
        # Use children(recursive=True) to get all descendants
        descendants = process.children(recursive=True)
        descendants.append(process)
        for p in descendants:
            p.kill()
    except psutil.NoSuchProcess:
        pass

def evaluate_code(code, test_cases, language_suffix):
    tmpdir = tempfile.mkdtemp()
    src_file = tmpdir + '/Main.' + language_suffix
    test_dir = tmpdir + '/test'
    os.makedirs(test_dir, exist_ok=True)

    test_no = 1
    # Write the source file.
    with open(src_file, 'w') as f:
        f.write(code)
    # Write the test files.
    for test_case in test_cases:
        with open(test_dir + '/test' + str(test_no) + '.in', 'w') as f:
            f.write(test_case['input'])
        with open(test_dir + '/test' + str(test_no) + '.ans', 'w') as f:
            f.write(test_case['output'])
        test_no += 1

    passed = 0
    total = len(test_cases)
    exec_timeout = 30

    for i in range(total):
        _test_no = i + 1
        command = "TIMEOUT_DURATION=10s /tp_workspace/scripts/scripts/bin/bench run " + src_file + " " + test_dir + '/test' + str(_test_no) + '.in'
        process = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=exec_timeout)

        stdout = process.stdout.decode('utf-8')
        stderr = process.stderr.decode('utf-8')

        stdout_arr = stdout.split("\\n")
        if "ok" in stdout_arr:
            passed += 1

    shutil.rmtree(tmpdir)
    success_rate = (passed / total)
    return success_rate


if __name__ == '__main__':
    code_snippet = {code}
    test_cases = json.loads({test_cases})

    language_suffix = '{language_suffix}'
    success_rate = evaluate_code(code_snippet, test_cases, language_suffix)
    print(success_rate)
"""


def local_code_reward(
    concurrent_semaphore: threading.Semaphore,
    memory_limit_mb: int,
    solution_str: str,
    ground_truth: str,
    extra_info: Dict[str, Any],
    **kwargs: Any,
) -> float:
    """Execute the generated code in a sandbox and return the pass rate.

    Parameters
    ----------
    concurrent_semaphore:
        Semaphore that limits the number of concurrent sandbox executions.
    memory_limit_mb:
        (Reserved) memory limit in MB for the sandbox process.
    solution_str:
        The full model response (including ``<think>`` / ``<answer>`` tags).
    ground_truth:
        JSON string containing ``inputs`` and ``outputs`` lists.
    extra_info:
        Must contain a ``language`` key indicating the target language.

    Returns
    -------
    float
        Pass rate in [0.0, 1.0].
    """
    language = extra_info["language"]
    code_snippet = extract_code(solution_str, language)
    print("Solution length and language: ", len(solution_str), language)

    # Build test cases from ground truth.
    verification_info = json.loads(ground_truth)
    test_cases = []
    for i in range(len(verification_info["inputs"])):
        test_case = {}
        test_case["input"] = verification_info["inputs"][i]
        test_case["output"] = verification_info["outputs"][i]
        test_cases.append(test_case)

    # Render the sandbox script.
    script = _EXECUTION_SCRIPT_TEMPLATE.format(
        code=json.dumps(code_snippet),
        test_cases=json.dumps(json.dumps(test_cases)),
        language_suffix=LANGUAGE_TO_SUFFIX[language],
    )

    with concurrent_semaphore:
        try:
            command = (
                f'tmpdir=$(mktemp -d) && '
                f'cat << \'EOF\' > "$tmpdir/calculate_pass_rate.py" && '
                f'source $HOME/trans/bin/activate && '
                f'python3 $tmpdir/calculate_pass_rate.py && '
                f'rm -rf "$tmpdir"\n{script}\nEOF'
            )
            result = subprocess.run(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                executable="/bin/bash",
            )

            stdout = result.stdout.decode("utf-8")
            stderr = result.stderr.decode("utf-8")

            reward = 0.0
            try:
                if hasattr(result, "text") and result.text:
                    result_text = result.text.decode("utf-8")
                    lines = result_text.strip().split("\n")
                    if lines:
                        try:
                            reward = float(lines[-1])
                        except ValueError:
                            try:
                                reward = float(result_text.strip())
                            except ValueError:
                                pass
                elif hasattr(result, "stdout") and result.stdout:
                    result_stdout = result.stdout.decode("utf-8")
                    if result_stdout and isinstance(result_stdout, str):
                        try:
                            reward = float(result_stdout)
                        except ValueError:
                            pass
                else:
                    print("Result has no text and stdout.")

            except (ValueError, AttributeError):
                print("ValueError and AttributeError.")
                pass

            return reward

        except Exception:
            print("Semaphore general error and 0 reward!")
            return 0.0

    return 0.0


# ---------------------------------------------------------------------------
# Aggressive reward shaping
# ---------------------------------------------------------------------------


def aggressive_reward(reward: float, lambda_arg: float) -> float:
    """Apply a non-linear *aggressive* transformation to the pass rate.

    Maps ``reward`` in [0, 1] through ``(1 - lambda^{-r}) / (1 - lambda^{-1})``,
    which penalizes partially-correct solutions more heavily than a linear
    function would.
    """
    return (1 - lambda_arg ** (-reward)) / (1 - lambda_arg ** (-1))


# ---------------------------------------------------------------------------
# Composite score
# ---------------------------------------------------------------------------

# Default hyper-parameters for the composite reward.
_WEIGHT_EXEC = 0.8
_WEIGHT_CODE_FMT = 0.1
_WEIGHT_FMT = 0.1
_LAMBDA_AGGRESSIVE = 20


def compute_score(
    concurrent_semaphore: threading.Semaphore,
    memory_limit_mb: int,
    solution_str: str,
    ground_truth: str,
    extra_info: Dict[str, Any],
) -> float:
    """Compute the composite reward for a single response.

    The final score is a weighted sum of three components:

    * **Execution reward** (weight 0.8): pass rate transformed by
      :func:`aggressive_reward` with ``lambda=20``.
    * **Code-format reward** (weight 0.1): whether the answer contains a
      properly fenced code block.
    * **Format reward** (weight 0.1): whether the response follows the
      ``<think>``/``<answer>`` structure.
    """
    format_score = format_reward(solution_str)
    code_format_score = get_code_format_reward(solution_str, extra_info["language"])
    pass_rate_score = local_code_reward(
        concurrent_semaphore, memory_limit_mb,
        solution_str, ground_truth, extra_info,
    )

    final_score = (
        _WEIGHT_EXEC * aggressive_reward(pass_rate_score, _LAMBDA_AGGRESSIVE)
        + _WEIGHT_CODE_FMT * code_format_score
        + _WEIGHT_FMT * format_score
    )
    return final_score
