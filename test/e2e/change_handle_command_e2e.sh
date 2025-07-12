#!/usr/bin/env bash
# vim: sw=2 ts=2 expandtab

# End-to-end test for the 'change-handle' command

STODO_CLIENT_REPL="$(dirname "$0")"/../../src/stodo_client_repl
USER_ID="test_user_change_handle_e2e"
APP_NAME="test_app_change_handle_e2e"
echo "user: $USER_ID"
echo "app:  $APP_NAME"

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

  if diff_output=$(diff -u "$expected_file" "$actual_file"); then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name"
    echo "  Differences found:"
    echo "$diff_output"
    return 1
  fi

  rm -f "$actual_file" "$expected_file"
  return 0
}

# Cleanup function
cleanup() {
  echo "--- Cleaning up test data ---"
  echo "delete old_handle_e2e" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete new_handle_e2e" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete existing_handle_e2e" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete test_item_e2e_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete other_existing_handle_e2e " | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
}

# Ensure cleanup runs on exit
trap cleanup EXIT

# Test cases
tests_passed=0
tests_failed=0

# Pre-create items for change-handle tests
echo "add task -h old_handle_e2e -t 'Task with old handle.' -d 'Description for old handle.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h existing_handle_e2e -t 'Existing task.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h other_existing_handle_e2e -t 'Other_existing task.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1

# Test 1: Successful change of handle
if run_test "Successful change handle" "Succeeded" \
  "change_handle old_handle_e2e new_handle_e2e"; then
  ((tests_passed++))
  # Verify old handle no longer exists
  if echo "report handle old_handle_e2e" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "Warning: Item with handle 'old_handle_e2e' not found."; then
    echo "PASS: Old handle 'old_handle_e2e' no longer exists."
  else
    echo "FAIL: Old handle 'old_handle_e2e' still exists or unexpected output."
    ((tests_failed++))
  fi
  # Verify new handle exists with correct content
  if echo "report complete new_handle_e2e" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "Task with old handle."; then
    echo "PASS: New handle 'new_handle_e2e' exists with correct content."
  else
    echo "FAIL: New handle 'new_handle_e2e' does not exist or has incorrect content."
    ((tests_failed++))
  fi
else
  ((tests_failed++))
fi

# Test 2: Attempt to change a non-existent handle
if run_test "Change non-existent handle" "Command failed: No item with handle 'non_existent_handle' found." \
  "change_handle non_existent_handle another_new_handle"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 3: Attempt to change a handle to an empty string
if run_test "Change handle to empty string" "Command failed: New handle cannot be empty." \
  "change_handle old_handle_e2e \"\""; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 4: Attempt to change a handle to the same handle
if run_test "Change handle to same handle" "Command failed: New handle cannot be the same as the old handle." \
  "change_handle old_handle_e2e old_handle_e2e"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 5: Attempt to change a handle to an already existing handle
if run_test "Change handle to existing handle" "Command failed: New handle cannot the handle of an existing item." \
  "change_handle other_existing_handle_e2e existing_handle_e2e"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Final result
if [ $tests_failed -eq 0 ]; then
  echo -e "\nAll change-handle command E2E tests passed!"
  exit 0
else
  echo -e "\n$tests_failed change-handle command E2E test(s) failed."
  exit 1
fi
