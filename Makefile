# Lufsa Makefile
# by default we always build debug.
.PHONY: debug
debug:
	rm -rf ./build
	xcodebuild -scheme Lufsa -configuration Debug archive -archivePath build/Lufsa.xcarchive

.PHONY: clean
clean:
	rm -rf ./build

.PHONY: release
release:
	rm -rf ./build
	xcodebuild -scheme Lufsa -configuration Release archive -archivePath build/Lufsa.xcarchive

