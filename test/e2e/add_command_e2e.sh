#!/usr/bin/env bash

# End-to-end test for the 'add' command

STODO_CLIENT_REPL="$(dirname "$0")"/../../src/stodo_client_repl
USER_ID="test_user_add_e2e"
APP_NAME="test_app_add_e2e"

# Function to run a command and check its output
run_test() {
  local test_name="$1"
  local expected_output_regex="$2"
  local command_args=("${@:3}")

  echo "--- Running Test: $test_name ---"
  # Execute the command and capture output
  output=$(echo "${command_args[*]}" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1)
  local exit_code=$?

  if echo "$output"|grep -Pzo "$expected_output_regex"; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name"
    echo "  Expected regex: '$expected_output_regex'"
    echo "  Actual output:  '$output'"
    return 1
  fi
  return 0
}

# Cleanup function
cleanup() {
  echo "--- Cleaning up test data ---"
  # In a real scenario, you'd need a way to delete items from Redis.
  # For now, we'll assume the server is reset or handles cleanup.
  # If the server persists data, this would need a 'stodo delete' or direct Redis flush.
  # For this test, we'll rely on the fact that the server is likely ephemeral or has a cleanup mechanism.
  # If not, this test might leave residue.
  echo "Cleanup placeholder: Manual Redis cleanup might be required if data persists."
}

# Ensure cleanup runs on exit
trap cleanup EXIT

# Test cases
tests_passed=0
tests_failed=0

# Test 1: Successful addition of a new item
if run_test "Successful add" ">? *got 'Succeeded' from server" \
  "add task -h test_item_e2e_1 -d 'This is an E2E test task.'"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 2: Attempt to add an item with '{none}' as a handle
if run_test "Add with {none} handle" ".*got 'Command failed: Problem with specification for item: {none} is not allowed as an item handle.' from server.*" \
  "add task -h {none} -d 'This should fail.'"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 3: Attempt to add an item with an invalid parent handle
if run_test "Add with invalid parent" ">? *got 'Command failed: Problem with specification for item: parent handle invalid or parent does not exist \(non_existent_parent\) for item child_item_e2e' from server" \
  "add task -h child_item_e2e -d 'Child task.' -p non_existent_parent"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Final result
if [ $tests_failed -eq 0 ]; then
  echo "\nAll add command E2E tests passed!"
  exit 0
else
  echo "\n$tests_failed add command E2E test(s) failed."
  exit 1
fi
