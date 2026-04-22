#!/bin/bash
# ===========================================================================
# run_grpo_qwen_7b.sh — GRPO training script for Qwen2.5-Coder-7B-Instruct.
#
# Before running, update the following paths:
#   - data.val_files                   — path to the evaluation parquet file
#   - actor_rollout_ref.model.path     — path to the SFT checkpoint
#   - trainer.default_local_dir        — output directory for RL checkpoints
#
# Usage:
#   bash run_grpo_qwen_7b.sh [additional overrides...]
# ===========================================================================

MAX_TOKEN_PER_GPU=22528
GPU_MEMORY_UTILIZATION=0.5

python3 -m verl.trainer.main_ppo \
    algorithm.adv_estimator=grpo \
    reward_model.sandbox_fusion.url="localhost:8080" \
    reward_model.sandbox_fusion.max_concurrent=30 \
    data.train_files=rl_train_data.parquet \
    data.val_files=/path/to/eval_data.parquet \
    data.train_batch_size=32 \
    data.val_batch_size=512 \
    data.max_prompt_length=5120 \
    data.max_response_length=16384 \
    actor_rollout_ref.model.path=/path/to/Qwen2.5-Coder-7B-Instruct-Full-SFT \
    actor_rollout_ref.actor.optim.lr=1e-6 \
    actor_rollout_ref.actor.optim.weight_decay=0.0 \
    actor_rollout_ref.actor.grad_clip=0.5 \
    actor_rollout_ref.rollout.enable_chunked_prefill=True \
    actor_rollout_ref.rollout.max_num_batched_tokens=21504 \
    actor_rollout_ref.actor.use_dynamic_bsz=True\
    actor_rollout_ref.actor.ppo_max_token_len_per_gpu=$MAX_TOKEN_PER_GPU \
    actor_rollout_ref.model.use_remove_padding=True \
    actor_rollout_ref.actor.ppo_mini_batch_size=8 \
    actor_rollout_ref.actor.use_kl_loss=True \
    actor_rollout_ref.actor.kl_loss_coef=0.000 \
    actor_rollout_ref.actor.kl_loss_type=low_var_kl \
    actor_rollout_ref.model.enable_gradient_checkpointing=True \
    actor_rollout_ref.actor.fsdp_config.param_offload=False \
    actor_rollout_ref.actor.fsdp_config.optimizer_offload=False \
    actor_rollout_ref.rollout.log_prob_max_token_len_per_gpu=$MAX_TOKEN_PER_GPU \
    actor_rollout_ref.rollout.tensor_model_parallel_size=2 \
    actor_rollout_ref.rollout.name=vllm \
    actor_rollout_ref.rollout.n=8 \
    actor_rollout_ref.rollout.val_kwargs.n=1 \
    actor_rollout_ref.rollout.temperature=1.0 \
    actor_rollout_ref.rollout.val_kwargs.temperature=1.0 \
    actor_rollout_ref.rollout.val_kwargs.do_sample=True \
    actor_rollout_ref.rollout.gpu_memory_utilization=$GPU_MEMORY_UTILIZATION \
    actor_rollout_ref.rollout.enforce_eager=False \
    actor_rollout_ref.rollout.free_cache_engine=True \
    actor_rollout_ref.ref.fsdp_config.param_offload=False \
    algorithm.kl_ctrl.kl_coef=0.000 \
    reward_model.reward_manager=prime \
    ray_init.num_cpus=68 \
    trainer.critic_warmup=0 \
    trainer.logger=['console','wandb'] \
    trainer.project_name='transpilation-r' \
    trainer.experiment_name='transpilation-run' \
    trainer.n_gpus_per_node=8 \
    trainer.nnodes=1 \
    trainer.val_before_train=True \
    trainer.default_local_dir=/path/to/Qwen2.5-coder-Instruct_v2 \
    trainer.default_hdfs_dir=null \
    trainer.save_freq=25 \
    trainer.test_freq=50 \
    trainer.total_epochs=100 "${@:1}"
