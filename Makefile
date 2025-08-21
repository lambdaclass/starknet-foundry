.PHONY: bench
bench:
	cargo b --release --bin snforge
	./scripts/benchmarks.sh $(SKIP)
