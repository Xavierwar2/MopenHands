#!/bin/bash


BASE_SCRIPT="./evaluation/benchmarks/swe_bench/scripts/run_infer.sh"

MODELS=("gpt54")
GIT_VERSION="HEAD"
AGENT_NAME="CodeActAgent"
EVAL_LIMIT="500"
MAX_ITER="50"
NUM_WORKERS="1"
LANGUAGE="typescript"
DATASET="./evaluation/benchmarks/swe_bench/data/mui__material-ui_dataset.jsonl"
OUTPUT_DIR="./evaluation/evaluation_outputs/mui"
SKIP_EXISTING_OUTPUT=true
SKIP_LOCAL_RUNTIME_BROWSER_CHECK=true
CONFIG_FILE="config.toml"
TEST_CASES_FILE="./evaluation/benchmarks/swe_bench/data/test_cases/mui.jsonl"
CLEANUP_RUNTIME_IMAGE=true
RUNTIME="local"
LOCAL_REPO_BASE_DIR="./evaluation/benchmarks/swe_bench/data/mui/material-ui"

usage() {
    echo "Usage: $0 [-o|--output <output_dir>] [--config-file <config_file>] [--test-cases-file <jsonl_file>] [--runtime <docker|local>] [--local-repo-base-dir <dir>] [--skip-existing-output|--no-skip-existing-output] [--cleanup-runtime-image|--no-cleanup-runtime-image]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            if [ -z "$2" ]; then
                echo "Error: $1 requires an output directory"
                usage
                exit 1
            fi
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --config-file)
            if [ -z "$2" ]; then
                echo "Error: $1 requires a config file"
                usage
                exit 1
            fi
            CONFIG_FILE="$2"
            shift 2
            ;;
        --test-cases-file|--test-case-file|--instance-ids-file)
            if [ -z "$2" ]; then
                echo "Error: $1 requires a jsonl file"
                usage
                exit 1
            fi
            TEST_CASES_FILE="$2"
            shift 2
            ;;
        --runtime)
            if [ -z "$2" ]; then
                echo "Error: $1 requires a runtime"
                usage
                exit 1
            fi
            RUNTIME="$2"
            shift 2
            ;;
        --local-repo-base-dir)
            if [ -z "$2" ]; then
                echo "Error: $1 requires a directory"
                usage
                exit 1
            fi
            LOCAL_REPO_BASE_DIR="$2"
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
        --cleanup-runtime-image)
            CLEANUP_RUNTIME_IMAGE=true
            shift
            ;;
        --no-cleanup-runtime-image)
            CLEANUP_RUNTIME_IMAGE=false
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            usage
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
        "$CONFIG_FILE" \
        "$TEST_CASES_FILE" \
        "$CLEANUP_RUNTIME_IMAGE" \
        "$RUNTIME" \
        "$LOCAL_REPO_BASE_DIR"

    echo "Completed $MODEL"
    echo
    done
