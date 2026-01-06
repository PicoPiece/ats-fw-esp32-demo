#!/bin/bash
# Test Docker Volume Mount Locally
# This script helps debug Docker mount issues before running in Jenkins pipeline

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Docker Volume Mount Test Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create test workspace
TEST_DIR="/tmp/docker-mount-test-$(date +%s)"
mkdir -p "${TEST_DIR}"
echo "📁 Created test directory: ${TEST_DIR}"

# Create test files
echo "manifest_version: 1" > "${TEST_DIR}/ats-manifest.yaml"
echo "test: data" > "${TEST_DIR}/test-file.txt"
mkdir -p "${TEST_DIR}/results"
echo "Test result" > "${TEST_DIR}/results/test-result.txt"

echo "✅ Created test files:"
ls -lah "${TEST_DIR}/"
echo ""

# Test 1: Basic mount test
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Basic Alpine mount test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

MOUNT_TEST=$(docker run --rm -v "${TEST_DIR}:/workspace" alpine:latest sh -c "ls -lah /workspace/ 2>&1")
echo "Mount test output:"
echo "${MOUNT_TEST}"
echo ""

FILE_COUNT=$(echo "${MOUNT_TEST}" | grep -v "^\.\.\?$" | grep -v "^total" | wc -l)
echo "Files found in mount: ${FILE_COUNT}"

if [ "${FILE_COUNT}" -lt 3 ]; then
    echo "❌ FAIL: Mount shows empty or incomplete directory"
    echo "   Expected at least 3 files (ats-manifest.yaml, test-file.txt, results/)"
else
    echo "✅ PASS: Mount shows files"
fi
echo ""

# Test 2: File access test
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Actual file access test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

FILE_TEST=$(docker run --rm -v "${TEST_DIR}:/workspace" alpine:latest sh -c "test -f /workspace/ats-manifest.yaml && echo 'FILE_EXISTS' || echo 'FILE_MISSING'" 2>&1)
echo "File test result: ${FILE_TEST}"

if echo "${FILE_TEST}" | grep -q "FILE_EXISTS"; then
    echo "✅ PASS: File is accessible in container"
    echo ""
    echo "File content:"
    docker run --rm -v "${TEST_DIR}:/workspace" alpine:latest cat /workspace/ats-manifest.yaml
else
    echo "❌ FAIL: File is NOT accessible in container"
fi
echo ""

# Test 3: Write test
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Write test (create file in container)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker run --rm -v "${TEST_DIR}:/workspace" alpine:latest sh -c "echo 'Written from container' > /workspace/container-write.txt" 2>&1

if [ -f "${TEST_DIR}/container-write.txt" ]; then
    echo "✅ PASS: Can write files from container"
    echo "   Content: $(cat "${TEST_DIR}/container-write.txt")"
else
    echo "❌ FAIL: Cannot write files from container"
fi
echo ""

# Test 4: Test with actual ats-node-test image
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Test with ats-node-test image (if available)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker images | grep -q "ats-node-test"; then
    IMAGE_NAME=$(docker images | grep "ats-node-test" | head -1 | awk '{print $1":"$2}')
    echo "Using image: ${IMAGE_NAME}"
    echo ""
    
    echo "Testing entrypoint with test workspace..."
    docker run --rm \
        -v "${TEST_DIR}:/workspace" \
        -e MANIFEST_PATH=/workspace/ats-manifest.yaml \
        -e RESULTS_DIR=/workspace/results \
        "${IMAGE_NAME}" 2>&1 | head -30 || echo "Container exited (expected if manifest is valid)"
else
    echo "⚠️  ats-node-test image not found, skipping this test"
    echo "   Build it first: cd ats-ats-node/docker/ats-node-test && docker build -t ats-node-test:latest ."
fi
echo ""

# Test 5: Check Docker socket and permissions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5: Docker environment check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Docker version:"
docker --version
echo ""

echo "Docker info (partial):"
docker info 2>&1 | head -10
echo ""

echo "Current user: $(whoami)"
echo "User ID: $(id -u)"
echo "Groups: $(groups)"
echo ""

echo "Docker socket permissions:"
ls -lah /var/run/docker.sock 2>&1 || echo "   Docker socket not found"
echo ""

# Test 6: Nested container test (if running in container)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 6: Container detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f /.dockerenv ]; then
    echo "⚠️  Running inside a container (/.dockerenv exists)"
    echo "   This is a Docker-in-Docker scenario"
    echo "   Mount paths may need special handling"
elif grep -qa docker /proc/1/cgroup 2>/dev/null; then
    echo "⚠️  Running inside a container (docker in cgroup)"
    echo "   This is a Docker-in-Docker scenario"
else
    echo "✅ Running directly on host"
fi
echo ""

# Cleanup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Delete test directory ${TEST_DIR}? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "${TEST_DIR}"
    echo "✅ Test directory deleted"
else
    echo "⚠️  Test directory kept: ${TEST_DIR}"
    echo "   You can inspect it manually"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Test completed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

