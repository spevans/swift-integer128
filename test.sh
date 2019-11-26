#!/bin/sh

MACOS_TESTS="Passed"
LINUX_TESTS="Passed"

swift test || MACOS_TESTS="Failed"
docker build --tag=intlarge-tests:$(date +%s) . || LINUX_TESTS="Failed"

echo
echo macOS tests ${MACOS_TESTS}
echo Linux tests ${LINUX_TESTS}
