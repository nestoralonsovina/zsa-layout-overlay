.PHONY: build run clean install lint

build:
	swift build

run:
	swift run zsa-layout-overlay

clean:
	rm -rf .build/

install:
	swift build -c release
	cp .build/release/zsa-layout-overlay /usr/local/bin/zsa-layout-overlay

lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --quiet; \
	else \
		echo "swiftlint not installed, skipping lint"; \
	fi
