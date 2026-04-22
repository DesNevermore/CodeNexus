# CodePivot

### Bootstrapping Multilingual Transpilation in LLMs via Reinforcement Learning without Parallel Corpora

[![arXiv](https://img.shields.io/badge/arXiv-2604.18027-b31b1b.svg)](https://arxiv.org/abs/2604.18027)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

CodePivot is an open-source training framework for large language models (LLMs) designed for **multilingual code transpilation**. It leverages **Python as an intermediate representation (IR)**, augmented by a novel reinforcement learning reward mechanism — the **Aggressive-Partial-Functional (APF) reward** — to bootstrap multilingual transpilation ability across 10 programming languages without requiring parallel corpora.

We open-source the full pipeline — dataset, sandboxed evaluation tooling, SFT configuration, and GRPO RL training script — used to produce a 7B model that outperforms substantially larger mainstream LLMs on transpilation benchmarks.

- 📄 **Paper:** [CodePivot: Bootstrapping Multilingual Transpilation in LLMs via Reinforcement Learning without Parallel Corpora](https://arxiv.org/abs/2604.18027)
- 💻 **Data:** `dataset/dataset.zip`
- 🌐 **Supported Languages:** C, C++, C#, Go, Haskell, Java, JavaScript, Perl, Python, Ruby, Rust
  - Easily extensible — add new languages by dropping a script into `scripts/scripts/languages/`.

---

## Environments

CodePivot depends on two components: (1) **sandboxed language runtimes** for code execution during reward computation, and (2) the standard **SFT / RL training** stacks.

### 1. Language Runtimes

```bash
cd ./scripts
bash install.sh
```

This installs the necessary system dependencies and configures all 11 language runtimes used during reward computation.

> **Note:** The installation scripts are currently written for **Ubuntu 20.04**. To support other systems, modify the `install_dependency()` function in the corresponding language scripts under `scripts/scripts/languages/`.

### 2. SFT Environment

We use [LLaMA-Factory](https://github.com/hiyouga/LLaMA-Factory) for supervised fine-tuning. Please follow its installation instructions.

### 3. RL Environment

We use [verl](https://github.com/volcengine/verl) for GRPO training with **Python 3.10**. Please follow its installation instructions.

### Language Runtime Versions

| Language   | Runtime / Compiler                     |
| ---------- | -------------------------------------- |
| C / C++    | GCC 9.4.0 (C++17), JsonCpp            |
| C#         | .NET 9 SDK (9.0.203)                   |
| Go         | go1.24.4 linux/amd64                   |
| Haskell    | GHC 8.6.5, aeson                       |
| Java       | OpenJDK 17.0.15, Jackson (FasterXML)   |
| JavaScript | Node.js v22.18.0                       |
| Perl       | Perl 5.30.0, JSON module               |
| Python     | Python 3                               |
| Ruby       | Ruby 3.2.2                             |
| Rust       | rustc 1.75.0 / cargo 1.75.0, serde_json |

---

## SFT Training

The provided SFT configuration targets `Qwen2.5-Coder-7B-Instruct` with full fine-tuning via DeepSpeed ZeRO-3.

```bash
# From within LLaMA-Factory, register the dataset and run:
llamafactory-cli train sft/qwen2.5-7b-instruct_sft.yaml
```

---

## RL Training

We use [verl](https://github.com/volcengine/verl) for RL training with the GRPO algorithm and a sandbox code-execution reward based on the APF reward formulation. Please refer to `verl/README.md` for more details.

The training script is at `verl/recipe/grpo/`:
```bash
cd verl/recipe/grpo
bash run_grpo_qwen_7b.sh
```

---

## Evaluation

The benchmark datasets are located in `dataset/`:

- **`evaluation_py2others.jsonl`** — Python → {C++, C#, Go, Haskell, Java, JavaScript, Perl, Ruby, Rust}
- **`evaluation_others2all.jsonl`** — All other language pairs

The system prompt used for inference is defined in `prompts/SYS_PROMPT`. It instructs the model to produce chain-of-thought reasoning inside `<think>...</think>` tags followed by the transpiled code inside `<answer>...</answer>` tags.

Functional correctness is determined by executing the generated code against per-task test cases inside the sandbox provided by `scripts/`. See [`scripts/README.md`](scripts/README.md) for details on the benchmark CLI.

---

## Citation

If you use the code, datasets, or models from this project, please cite:

```bibtex
@misc{li2026codepivot,
  title         = {CodePivot: Bootstrapping Multilingual Transpilation in LLMs via Reinforcement Learning without Parallel Corpora},
  year          = {2026},
  eprint        = {2604.18027},
  archivePrefix = {arXiv},
  primaryClass  = {cs.SE},
  url           = {https://arxiv.org/abs/2604.18027}
}
```
