#!/bin/bash
# Lint the project's podspec using the appropriate sources.
# Possible to pass in additional switches, e.g. --no-clean, --verbose etc.
SOURCES="ssh://git@git.innerfunction.com:22222/julian/if-podspecs.git,https://github.com/CocoaPods/Specs.git"
ARGS="$*"
pod lib lint --sources=$SOURCES $ARGS --allow-warnings --verbose semo-content-ios.podspec
