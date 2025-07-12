#!/usr/bin/env bash

# End-to-end test for the 'clone' command

STODO_CLIENT_REPL="$(dirname "$0")"/../../src/stodo_client_repl
USER_ID="test_user_clone_e2e"
APP_NAME="test_app_clone_e2e"
echo "user: $USER_ID"
echo "app:  $APP_NAME"

# Function to run a command and capture its output
run_command() {
  local command_args=("$@")
  echo "${command_args[*]}" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1
}

# Function to run a test case
run_test() {
  local test_name="$1"
  local expected_output_heredoc="$2"
  local command_args=("${@:3}")

  echo "--- Running Test: $test_name ---"

  local raw_output=$(run_command "${command_args[@]}")
  local actual_output=$(echo "$raw_output" | sed -e "s/^> //g" -e '$s/\n*$//' -e '/^temporary-session-id/d')
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
    rm -f "$actual_file" "$expected_file"
    return 0
  else
    echo "FAIL: $test_name"
    echo "  Differences found:"
    echo "$diff_output"
    rm -f "$actual_file" "$expected_file"
    return 1
  fi
}

# Cleanup function
cleanup() {
  echo "--- Cleaning up test data ---"
  run_command "delete source_item" > /dev/null 2>&1
  run_command "delete cloned_item" > /dev/null 2>&1
  run_command "delete source_parent_recursive" > /dev/null 2>&1
  run_command "delete source_child_recursive" > /dev/null 2>&1
  run_command "delete source_grandchild_recursive" > /dev/null 2>&1
  run_command "delete cloned_parent_recursive" > /dev/null 2>&1
  run_command "delete cloned_child_recursive" > /dev/null 2>&1
  run_command "delete cloned_grandchild_recursive" > /dev/null 2>&1
}

# Ensure cleanup runs on exit
trap cleanup EXIT

# Test cases
tests_passed=0
tests_failed=0

# --- Test 1: Basic Clone ---
run_command "add task -h source_item -t 'Source Item Title' -d 'Source Item Description'" > /dev/null

if run_test "Basic Clone" "Succeeded" "clone source_item cloned_item"; then
  ((tests_passed++))
  # Verify the cloned item exists and has the correct properties
  cloned_report=$(run_command "report complete cloned_item")
  if echo "$cloned_report" | grep -q "Title:       Source Item Title" && \
     echo "$cloned_report" | grep -q "Description: Source Item Description"; then
    echo "PASS: Cloned item properties are correct."
  else
    echo "FAIL: Cloned item properties are incorrect."
    echo "Full report for cloned_item:"
    echo "$cloned_report"
    ((tests_failed++))
  fi
else
  ((tests_failed++))
fi

# --- Test 2: Recursive Clone ---
run_command "add task -h source_parent_recursive -t 'Source Parent Recursive'" > /dev/null
run_command "add task -h source_child_recursive -t 'Source Child Recursive' -p source_parent_recursive" > /dev/null
run_command "add task -h source_grandchild_recursive -t 'Source Grandchild Recursive' -p source_child_recursive" > /dev/null

if run_test "Recursive Clone" "Succeeded" "clone -r source_parent_recursive cloned_parent_recursive"; then
  ((tests_passed++))
  # Verify cloned parent exists and has correct properties
  cloned_parent_report=$(run_command "report complete cloned_parent_recursive")
  if echo "$cloned_parent_report" | grep -q "Title:       Source Parent Recursive"; then
    echo "PASS: Cloned parent recursive properties are correct."
  else
    echo "FAIL: Cloned parent recursive properties are incorrect."
    echo "Full report for cloned_parent_recursive:"
    echo "$cloned_parent_report"
    ((tests_failed++))
  fi

  # Verify cloned child exists and has correct properties and parent
  cloned_child_report=$(run_command "report complete cloned_child_recursive")
  if echo "$cloned_child_report" | grep -q "Title:       Source Child Recursive" && \
     echo "$cloned_child_report" | grep -q "Parent:      cloned_parent_recursive"; then
    echo "PASS: Cloned child recursive properties are correct."
  else
    echo "FAIL: Cloned child recursive properties are incorrect."
    echo "Full report for cloned_child_recursive:"
    echo "$cloned_child_report"
    ((tests_failed++))
  fi

  # Verify cloned grandchild exists and has correct properties and parent
  cloned_grandchild_report=$(run_command "report complete cloned_grandchild_recursive")
  if echo "$cloned_grandchild_report" | grep -q "Title:       Source Grandchild Recursive" && \
     echo "$cloned_grandchild_report" | grep -q "Parent:      cloned_child_recursive"; then
    echo "PASS: Cloned grandchild recursive properties are correct."
  else
    echo "FAIL: Cloned grandchild recursive properties are incorrect."
    echo "Full report for cloned_grandchild_recursive:"
    echo "$cloned_grandchild_report"
    ((tests_failed++))
  fi
else
  ((tests_failed++))
fi

# Final result
if [ $tests_failed -eq 0 ]; then
  echo "\nAll clone command E2E tests passed!"
  exit 0
else
  echo "\n$tests_failed clone command E2E test(s) failed."
  exit 1
fi
