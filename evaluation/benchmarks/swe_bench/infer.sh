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
OUTPUT_DIR="/root/Ref/MopenHands/evaluation/evaluation_outputs/vuejs"
SKIP_EXISTING_OUTPUT=true
CONFIG_FILE="config.toml"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            if [ -z "$2" ]; then
                echo "Error: $1 requires an output directory"
                echo "Usage: $0 [-o|--output <output_dir>] [--skip-existing-output|--no-skip-existing-output]"
                exit 1
            fi
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --config-file)
            if [ -z "$2" ]; then
                echo "Error: $1 requires a config file"
                echo "Usage: $0 [-o|--output <output_dir>] [--config-file <config_file>] [--skip-existing-output|--no-skip-existing-output]"
                exit 1
            fi
            CONFIG_FILE="$2"
            shift 2
            ;;
        --skip-existing-output)
            SKIP_EXISTING_OUTPUT=true
            shift
            ;;
        --no-skip-existing-output)
            SKIP_EXISTING_OUTPUT=false
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [-o|--output <output_dir>] [--config-file <config_file>] [--skip-existing-output|--no-skip-existing-output]"
            exit 1
            ;;
    esac
done


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
        "$LANGUAGE" \
        "$OUTPUT_DIR" \
        "$SKIP_EXISTING_OUTPUT" \
        "$CONFIG_FILE"

    echo "Completed $MODEL"
    echo
    done
