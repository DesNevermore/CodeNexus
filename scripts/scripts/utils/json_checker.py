"""JSON-aware output checker for the benchmark framework.

Compares the actual output file against the expected answer file with
structured type awareness:

  - **dict** -- deep comparison with ``DeepDiff`` (order-insensitive).
  - **list / array** -- element-wise comparison (floats rounded to 4 d.p.).
  - **int / float / bool / str** -- direct equality (floats rounded to 4 d.p.).

Exit codes (compatible with testlib conventions):
  0  -- ok
  1  -- wrong answer (fallback)
  3  -- checker failure / array mismatch
  4  -- int mismatch
  5  -- float mismatch
  6  -- bool mismatch
  7  -- string mismatch
  8  -- type mismatch (expected dict, got something else)
  9  -- dict diff detected
  10 -- unhandled type
  11 -- array formatting error
  12 -- output JSON parse error
"""

import sys
import json
import argparse
import numpy as np
from deepdiff import DeepDiff
import ast


def format_mixed_element(item):
    if isinstance(item, (int, float)):
        return round(item, 4)
    return item


def formatDict(d):
    if isinstance(d, dict):
        for key, value in d.items():
            if type(value) == dict:
                formatDict(value)
            if type(value) == float:
                d[key] = round(value, 4)
            if type(value) == list:
                try:
                    arr = np.array(value)
                    vectorized_formatter = np.vectorize(format_mixed_element)
                    if arr.size != 0:
                        d[key] = vectorized_formatter(arr)
                except Exception as e:
                    sys.exit(11)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=str,
                        default='/root/CompetitiveCode/testcodes/test1.out',
                        help='input file')
    parser.add_argument('--answer', type=str,
                        default='/root/CompetitiveCode/testcodes/test1.out',
                        help='input file')

    args = parser.parse_args()

    # Parse expected answer (may be plain text if not valid JSON).
    answer = ''
    with open(args.answer, 'r') as f:
        content = f.read()
        content = content.rstrip()
        try:
            answer = json.loads(content)
        except Exception:
            answer = content

    # Parse actual output (must be valid JSON).
    output = ''
    with open(args.output, 'r') as f:
        try:
            content = f.read()
            content = content.rstrip()
            output = json.loads(content)
        except Exception as e:
            sys.exit(12)

    # Dispatch comparison by type.
    if type(answer) == dict:
        if type(output) != dict:
            sys.exit(8)
        formatDict(answer)
        formatDict(output)
        diff = DeepDiff(output, answer, ignore_order=True)
        if not diff:
            sys.exit(0)
        else:
            sys.exit(9)
    else:
        if type(answer) == list:
            try:
                npOutputArr = np.array(output)
                npAnswerArr = np.array(answer)
                vectorized_formatter = np.vectorize(format_mixed_element)
                if npOutputArr.size != 0:
                    npOutputArr = vectorized_formatter(npOutputArr)
                if npAnswerArr.size != 0:
                    npAnswerArr = vectorized_formatter(npAnswerArr)
                if (npOutputArr == npAnswerArr).all():
                    sys.exit(0)
                else:
                    sys.exit(3)
            except Exception as e:
                sys.exit(3)

        if type(answer) == int:
            if type(output) == int:
                if output == answer:
                    sys.exit(0)
                else:
                    sys.exit(4)
            else:
                sys.exit(4)

        if type(answer) == float:
            if type(output) == float:
                answer = round(answer, 4)
                output = round(output, 4)
                if output == answer:
                    sys.exit(0)
                else:
                    sys.exit(5)
                pass
            else:
                sys.exit(5)

        if type(answer) == bool:
            if type(output) == bool:
                if output == answer:
                    sys.exit(0)
                else:
                    sys.exit(6)
            else:
                if type(output) == int:
                    if (output == 1 and answer) or (output == 0 and not answer):
                        sys.exit(0)
                    else:
                        sys.exit(6)
                if type(output) == float:
                    if ((output == 'True' or output == 'true') and answer) or \
                            ((output == 'False' or output == 'false') and not answer):
                        sys.exit(0)
                    else:
                        sys.exit(6)
                sys.exit(6)

        if type(answer) == str:
            if type(output) == str:
                if output == answer:
                    sys.exit(0)
                else:
                    sys.exit(7)
                pass
            else:
                sys.exit(7)

    sys.exit(10)
