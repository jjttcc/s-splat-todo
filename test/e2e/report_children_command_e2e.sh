#!/usr/bin/env bash

# End-to-end test for the 'report children' command

STODO_CLIENT_REPL="$(dirname "$0")"/../../src/stodo_client_repl
USER_ID="test_user_report_children_e2e"
APP_NAME="test_app_report_children_e2e"
echo "user: $USER_ID"
echo "app:  $APP_NAME"

# Function to run a command and capture its output
run_command() {
  local command_args=("$@")
  local user_arg="$USER_ID"
  local app_arg="$APP_NAME"
  local no_prompt_arg=""

  # Pass --no-prompt to stodo_client_repl for short format tests
  if [[ "${command_args[*]}" =~ "report children -s" ]]; then
    no_prompt_arg="--no-prompt"
  fi

  echo "${command_args[*]}" | "$STODO_CLIENT_REPL" "$user_arg" "$app_arg" "$no_prompt_arg" 2>&1
}

# Function to run a test case
run_test() {
  local test_name="$1"
  local expected_output_heredoc="$2"
  local command_args=("${@:3}")
  local current_date_time=$(date +"%Y-%m-%d %H:%M")

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
  echo -e "$expected_output" > "$expected_file"

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
  run_command "delete parent_rc_test" > /dev/null 2>&1
  run_command "delete child_rc_test_1" > /dev/null 2>&1
  run_command "delete child_rc_test_2" > /dev/null 2>&1
  run_command "delete grandchild_rc_test_1" > /dev/null 2>&1
  run_command "delete top_level_rc_test_1" > /dev/null 2>&1
  run_command "delete top_level_rc_test_2" > /dev/null 2>&1
}

# Ensure cleanup runs on exit
trap cleanup EXIT

# Test cases
tests_passed=0
tests_failed=0

# Test Data Hierarchy:
#
# parent_rc_test
#   child_rc_test_1
#     grandchild_rc_test_1
#   child_rc_test_2
# top_level_rc_test_1
# top_level_rc_test_2

# --- Setup Test Data ---
run_command "add task -h parent_rc_test -t 'Parent for Report Children Test' -ti '2025-07-10 01:00'" > /dev/null
run_command "add task -h child_rc_test_1 -t 'Child 1' -p parent_rc_test -ti '2025-07-10 01:00'" > /dev/null
run_command "add task -h child_rc_test_2 -t 'Child 2' -p parent_rc_test -ti '2025-07-10 01:00'" > /dev/null
run_command "add task -h grandchild_rc_test_1 -t 'Grandchild 1' -p child_rc_test_1 -ti '2025-07-10 01:00'" > /dev/null
run_command "add task -h top_level_rc_test_1 -t 'Top Level Item 1' -ti '2025-07-10 01:00'" > /dev/null
run_command "add task -h top_level_rc_test_2 -t 'Top Level Item 2' -ti '2025-07-10 01:00'" > /dev/null

# --- Test 1: Long format for a specific handle ---
if run_test "Long format for specific handle" "parent_rc_test, due: 2025-07-10 01:00 (in-progress)\n  child_rc_test_1, due: 2025-07-10 01:00 (in-progress)\n    grandchild_rc_test_1, due: 2025-07-10 01:00 (in-progress)\n  child_rc_test_2, due: 2025-07-10 01:00 (in-progress)" \
  "report children parent_rc_test"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# --- Test 2: Short format for a specific handle ---
if run_test "Short format for specific handle" "parent_rc_test\n  child_rc_test_1\n    grandchild_rc_test_1\n  child_rc_test_2" \
  "report children -s parent_rc_test"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# --- Test 3: Long format for all top-level items ---
if run_test "Long format for all top-level items" "parent_rc_test, due: 2025-07-10 01:00 (in-progress)\n  child_rc_test_1, due: 2025-07-10 01:00 (in-progress)\n    grandchild_rc_test_1, due: 2025-07-10 01:00 (in-progress)\n  child_rc_test_2, due: 2025-07-10 01:00 (in-progress)\ntop_level_rc_test_1, due: 2025-07-10 01:00 (in-progress)\ntop_level_rc_test_2, due: 2025-07-10 01:00 (in-progress)" \
  "report children"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# --- Test 4: Short format for all top-level items ---
if run_test "Short format for all top-level items" "parent_rc_test
  child_rc_test_1
    grandchild_rc_test_1
  child_rc_test_2
top_level_rc_test_1
top_level_rc_test_2" \
  "report children -s"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Final result
if [ $tests_failed -eq 0 ]; then
  echo -e "\nAll report children command E2E tests passed!"
  exit 0
else
  echo -e "\n$tests_failed report children command E2E test(s) failed."
  exit 1
fi