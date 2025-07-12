#!/usr/bin/env bash

# End-to-end test for the 'change' command

STODO_CLIENT_REPL="$(dirname "$0")"/../../src/stodo_client_repl
USER_ID="test_user_change_e2e"
APP_NAME="test_app_change_e2e"

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
  echo "delete test_item_e2e_change_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete parent_e2e_change_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete child_e2e_change_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete parent_e2e_change_2" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
}

# Ensure cleanup runs on exit
trap cleanup EXIT

# Test cases
tests_passed=0
tests_failed=0

# Pre-create items for change tests
echo "add task -h test_item_e2e_change_1 -d 'Original description.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h parent_e2e_change_1 -d 'Parent 1.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h parent_e2e_change_2 -d 'Parent 2.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h child_e2e_change_1 -d 'Child item.' -p parent_e2e_change_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1

# Test 1: Successful change of an item's description
if run_test "Successful change description" "Succeeded" \
  "change test_item_e2e_change_1 -d 'New description.'"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 2: Successful change of an item's parent
if run_test "Successful change parent" "Succeeded" \
  "change child_e2e_change_1 -p parent_e2e_change_2"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 3: Successful change of an item to be parentless ({none})
if run_test "Successful change to parentless" "Succeeded" \
  "change child_e2e_change_1 -p {none}"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 4: Attempt to change a non-existent item
if run_test "Change non-existent item" "Command failed: No item with handle 'non_existent_item' found." \
  "change non_existent_item -d 'Should not change.'"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 5: Attempt to change an item with an invalid new parent handle
if run_test "Change with invalid new parent" "Command failed: Invalid parent handle 'another_non_existent_parent'" \
  "change test_item_e2e_change_1 -p another_non_existent_parent"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Final result
if [ $tests_failed -eq 0 ]; then
  echo -e "\nAll change command E2E tests passed!"
  exit 0
else
  echo -e "\n$tests_failed change command E2E test(s) failed."
  exit 1
fi
