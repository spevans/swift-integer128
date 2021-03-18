#!/bin/sh

MACOS_TESTS="Passed"
LINUX_TESTS_LATEST="Passed"
LINUX_TESTS_5_1="Passed"
LINUX_TESTS_5_2="Passed"
LINUX_TESTS_5_3="Passed"

swift package clean
swift test || MACOS_TESTS="Failed"
docker build --tag=integer128-tests:$(date +%s) -f Dockerfile . || LINUX_TESTS_LATEST="Failed"
docker build --tag=integer128-tests:$(date +%s) -f Dockerfile-5.3 . || LINUX_TESTS_5_3="Failed"
docker build --tag=integer128-tests:$(date +%s) -f Dockerfile-5.2 . || LINUX_TESTS_5_2="Failed"
docker build --tag=integer128-tests:$(date +%s) -f Dockerfile-5.1 . || LINUX_TESTS_5_1="Failed"

echo
echo macOS tests ${MACOS_TESTS}
echo Linux latest tests ${LINUX_TESTS_LATEST}
echo Linux 5.3 tests ${LINUX_TESTS_5_1}
echo Linux 5.2 tests ${LINUX_TESTS_5_2}
echo Linux 5.1 tests ${LINUX_TESTS_5_3}
