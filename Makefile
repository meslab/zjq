test:
	@zig build test

run:
	@zig build run

clean:
	@rm -rf .zig-cache zig-out

install:
	@zig build --release=safe --prefix-exe-dir ~/.local/bin

.PHONY: clean test run install
