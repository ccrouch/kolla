#!/bin/sh
# based on devstack run_tests.sh

# script expects tests to be mounted at /tests
# TODO: add ability to launch python based tests too (need to pass env vars)

PASSES=""
FAILURES=""

pushd /tests/
for testfile in /tests/test_*.sh; do
    $testfile
    if [[ $? -eq 0 ]]; then
        PASSES="$PASSES $testfile"
    else
        FAILURES="$FAILURES $testfile"
    fi
done
popd

# Summary display now that all is said and done
echo "====================================================================="
for script in $PASSES; do
    echo PASS $script
done
for script in $FAILURES; do
    echo FAILED $script
done
echo "====================================================================="

if [[ -n "$FAILURES" ]]; then
    exit 1
fi
