#!/bin/bash
# Simple Docker Mount Test for Raspberry Pi
# Run this on the Pi to test if Docker mounts work

set -e

echo "🧪 Simple Docker Mount Test"
echo ""

# Create test file
TEST_DIR="/tmp/mount-test-$$"
mkdir -p "${TEST_DIR}"
echo "test: data" > "${TEST_DIR}/test.yaml"
echo "✅ Created test file: ${TEST_DIR}/test.yaml"
echo ""

# Test mount
echo "Testing Docker mount..."
RESULT=$(docker run --rm -v "${TEST_DIR}:/workspace" alpine:latest sh -c "cat /workspace/test.yaml" 2>&1)

if echo "${RESULT}" | grep -q "test: data"; then
    echo "✅ SUCCESS: Docker mount works!"
    echo "   File content: ${RESULT}"
else
    echo "❌ FAILED: Docker mount does NOT work"
    echo "   Output: ${RESULT}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check Docker is running: sudo systemctl status docker"
    echo "2. Check user is in docker group: groups | grep docker"
    echo "3. Check Docker socket: ls -l /var/run/docker.sock"
fi

# Cleanup
rm -rf "${TEST_DIR}"
echo ""
echo "Test completed"

