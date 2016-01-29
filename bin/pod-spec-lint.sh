#!/bin/bash
# Lint the project's podspec using the appropriate sources.
# Possible to pass in additional switches, e.g. --no-clean, --verbose etc.
ARGS="$*"
pod spec lint --allow-warnings --verbose $ARGS semo-content-ios.podspec

