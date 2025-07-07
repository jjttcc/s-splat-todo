#!/usr/bin/env bash

# End-to-end test for the 'add' command

STODO_CLIENT_REPL="$(dirname "$0")"/../../src/stodo_client_repl
USER_ID="test_user_add_e2e"
APP_NAME="test_app_add_e2e"

# Function to run a command and capture its output
run_command() {
  local command_args=("${@}")
  echo "${command_args[*]}" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1
}

# Function to run a test case
run_test() {
  local test_name="$1"
  local expected_output_heredoc="$2"
  local command_args=("${@:3}")

  echo "--- Running Test: $test_name ---"

  local raw_output=$(run_command "${command_args[@]}")
  local actual_output=$(echo "$raw_output" | sed -e "s/^> //g" | sed -e '$s/\n*$//')
  local expected_output=$(cat <<EOF
$expected_output_heredoc
EOF
)

  # Create temporary files for comparison
  local actual_file=$(mktemp)
  local expected_file=$(mktemp)

  echo "$actual_output" > "$actual_file"
  echo "$expected_output" > "$expected_file"

  if diff -u "$expected_file" "$actual_file"; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name"
    echo "  Differences found:"
    return 1
  fi

  rm -f "$actual_file" "$expected_file"
  return 0
}

# Cleanup function
cleanup() {
  echo "--- Cleaning up test data ---"
  # Delete items created during tests to ensure isolation
  echo "delete test_item_e2e_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete child_item_e2e" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
}

# Ensure cleanup runs on exit
trap cleanup EXIT

# Test cases
tests_passed=0
tests_failed=0

# Test 1: Successful addition of a new item
if run_test "Successful add" "Succeeded" \
  "add task -h test_item_e2e_1 -d 'This is an E2E test task.'"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 2: Attempt to add an item with '{none}' as a handle
if run_test "Add with {none} handle" "Command failed: Problem with specification for item: {none} is not allowed as an item handle." \
  "add task -h {none} -d 'This should fail.'"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 3: Attempt to add an item with an invalid parent handle
if run_test "Add with invalid parent" "Command failed: Problem with specification for item: parent handle invalid or parent does not exist (non_existent_parent) for item child_item_e2e" \
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
