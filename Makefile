.PHONY: build run clean install app lint

APP_NAME  = ZSALayoutOverlay
APP_DIR   = .build/$(APP_NAME).app
BINARY    = .build/release/zsa-layout-overlay
RESOURCES = Sources/Resources

build:
	swift build

run:
	swift run zsa-layout-overlay

clean:
	rm -rf .build/

install:
	swift build -c release
	cp $(BINARY) /usr/local/bin/zsa-layout-overlay

app: clean
	swift build -c release
	rm -rf $(APP_DIR)
	mkdir -p $(APP_DIR)/Contents/MacOS
	mkdir -p $(APP_DIR)/Contents/Resources
	mkdir -p $(APP_DIR)/Contents/Frameworks
	cp $(BINARY) $(APP_DIR)/Contents/MacOS/
	cp Info.plist $(APP_DIR)/Contents/
	for f in $(RESOURCES)/*.ttf; do cp $$f $(APP_DIR)/Contents/Resources/; done
	cp /opt/homebrew/opt/hidapi/lib/libhidapi.0.dylib $(APP_DIR)/Contents/Frameworks/
	install_name_tool -change /opt/homebrew/opt/hidapi/lib/libhidapi.0.dylib \
		@executable_path/../Frameworks/libhidapi.0.dylib \
		$(APP_DIR)/Contents/MacOS/zsa-layout-overlay 2>/dev/null || true
	codesign --force --deep --sign - $(APP_DIR) 2>/dev/null || true
	@echo "App built at $(APP_DIR)"

lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --quiet; \
	else \
		echo "swiftlint not installed, skipping lint"; \
	fi
