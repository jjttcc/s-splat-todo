#!/usr/bin/env bash

# End-to-end test for the 'clone' command

STODO_CLIENT_REPL="$(dirname "$0")"/../../src/stodo_client_repl
USER_ID="test_user_clone_e2e"
APP_NAME="test_app_clone_e2e"
recursion_implemented=false
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
  run_command "delete parent_for_clone_test" > /dev/null 2>&1
  run_command "delete child_for_clone_test" > /dev/null 2>&1
  run_command "delete cloned_parent_for_clone_test" > /dev/null 2>&1
  run_command "delete parent_of_complex_item" > /dev/null 2>&1
  run_command "delete complex_item" > /dev/null 2>&1
  run_command "delete child_of_complex_item" > /dev/null 2>&1
  run_command "delete cloned_complex_item" > /dev/null 2>&1
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

# --- Test 2: Clone with Parent and Children (Children should NOT be cloned) ---
run_command "add task -h parent_for_clone_test -t 'Parent for Clone Test'" > /dev/null
run_command "add task -h child_for_clone_test -t 'Child for Clone Test' -p parent_for_clone_test" > /dev/null

if run_test "Clone with Parent and Children" "Succeeded" "clone parent_for_clone_test cloned_parent_for_clone_test"; then
  ((tests_passed++))
  cloned_parent_report=$(run_command "report complete cloned_parent_for_clone_test")
  if echo "$cloned_parent_report" | grep -q "Title:       Parent for Clone Test" && \
     echo "$cloned_parent_report" | grep -q "Parent:      None" && \
     echo "$cloned_parent_report" | grep -q "Children: *$"; then
    echo "PASS: Cloned parent has correct properties (inherited parent, no children)."
  else
    echo "FAIL: Cloned parent has incorrect properties."
    echo "Full report for cloned_parent_for_clone_test:"
    echo "$cloned_parent_report"
    ((tests_failed++))
  fi

  # Verify the original child is NOT a child of the cloned parent
  if ! run_command "report children cloned_parent_for_clone_test" | grep -q "child_for_clone_test"; then
    echo "PASS: Original child is NOT a child of the cloned parent."
  else
    echo "FAIL: Original child IS a child of the cloned parent."
    ((tests_failed++))
  fi


else
  ((tests_failed++))
fi

# --- Test 3: Clone an item with both a parent and children ---
run_command "add task -h parent_of_complex_item -t 'Parent of Complex Item'" > /dev/null
run_command "add task -h complex_item -t 'Complex Item' -p parent_of_complex_item" > /dev/null
run_command "add task -h child_of_complex_item -t 'Child of Complex Item' -p complex_item" > /dev/null

if run_test "Clone Complex Item (with parent and children)" "Succeeded" "clone complex_item cloned_complex_item"; then
  ((tests_passed++))
  cloned_complex_report=$(run_command "report complete cloned_complex_item")
  if echo "$cloned_complex_report" | grep -q "Title:       Complex Item" &&      echo "$cloned_complex_report" | grep -q "Parent:      parent_of_complex_item" &&      echo "$cloned_complex_report" | grep -q "Children: *$"; then
    echo "PASS: Cloned complex item has correct properties (no children, no parent)."
  else
    echo "FAIL: Cloned complex item has incorrect properties."
    echo "Full report for cloned_complex_item:"
    echo "$cloned_complex_report"
    ((tests_failed++))
  fi

  # Verify original parent *is* parent of cloned item
  if run_command "report children parent_of_complex_item" | grep -q "cloned_complex_item"; then
    echo "PASS: Original parent IS parent of cloned item."
  else
    echo "FAIL: Original parent IS NOT parent of cloned item."
    ((tests_failed++))
  fi

  # Verify original child is NOT child of cloned item
  if ! run_command "report children cloned_complex_item" | grep -q "child_of_complex_item"; then
    echo "PASS: Original child is NOT child of cloned item."
  else
    echo "FAIL: Original child IS child of cloned item."
    ((tests_failed++))
  fi
else
  ((tests_failed++))
fi

# --- Test 4: Recursive Clone (Currently Disabled) ---
if $recursion_implemented; then     # (recursion is not yet implemented)
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
fi

# Final result
if [ $tests_failed -eq 0 ]; then
  echo -e "\nAll clone command E2E tests passed!"
  exit 0
else
  echo -e "\n$tests_failed clone command E2E test(s) failed."
  exit 1
fi
