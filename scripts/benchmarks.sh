#!/usr/bin/env bash

PROGRAMS_DIR="scarb_programs/"

run_bench() {
    hyperfine \
        --warmup 5 \
        '../../target/release/snforge test --use-native' \
        '../../target/release/snforge test --max-n-steps 100000000'
}

for dir in "$PROGRAMS_DIR"/*/; do
  (
    cd "$dir"
    run_bench
  )
done

