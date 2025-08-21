#!/usr/bin/env bash

PROGRAMS_DIR="scarb_programs/"
SKIP=$1

run_bench() {
    native_command='../../target/release/snforge test --use-native'
    vm_command='../../target/release/snforge test --max-n-steps 100000000'

    # If an argument was passed, it means we should use it as the string for the skip argument in snforge
    if [ -n "$SKIP" ]; then
      native_command+=" --skip $SKIP"
      vm_command+=" --skip $SKIP"
    fi

    hyperfine \
        --warmup 5 \
        "$native_command" \
        "$vm_command"
}

for dir in "$PROGRAMS_DIR"/*/; do
  (
    cd "$dir"
    run_bench
  )
done

