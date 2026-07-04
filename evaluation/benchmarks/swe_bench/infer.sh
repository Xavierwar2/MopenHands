#!/bin/bash


BASE_SCRIPT="./evaluation/benchmarks/swe_bench/scripts/run_infer.sh"

MODELS=("gpt54")
GIT_VERSION="HEAD"
AGENT_NAME="CodeActAgent"
EVAL_LIMIT="500"
MAX_ITER="50"
NUM_WORKERS="1"
LANGUAGE="typescript"
DATASET="./evaluation/benchmarks/swe_bench/data/vuejs_converted.jsonl"


for MODEL in "${MODELS[@]}"; do
    echo "=============================="
    echo "Running benchmark for MODEL: $MODEL"
    echo "=============================="

    bash "$BASE_SCRIPT" \
        "$MODEL" \
        "$GIT_VERSION" \
        "$AGENT_NAME" \
        "$EVAL_LIMIT" \
        "$MAX_ITER" \
        "$NUM_WORKERS" \
        "$DATASET" \
        "$LANGUAGE"

    echo "Completed $MODEL"
    echo
    done
