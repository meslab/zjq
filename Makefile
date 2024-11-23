test:
	@zig build test

run:
	@zig build run

clean:
	@rm -rf .zig-cache zig-out

.PHONY: clean test run
