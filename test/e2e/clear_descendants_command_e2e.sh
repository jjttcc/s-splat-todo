#!/usr/bin/env bash

# End-to-end test for the 'clear_descendants' command

STODO_CLIENT_REPL="$(dirname "$0")"/../../src/stodo_client_repl
USER_ID="test_user_clear_desc_e2e"
APP_NAME="test_app_clear_desc_e2e"
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
  echo "delete parent_clear_desc" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete child_clear_desc_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete child_clear_desc_2" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete grandchild_clear_desc_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete parent_exception_test" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete child_exception_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete child_exception_2" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete grandchild_exception_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete parent_hierarchy_test" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete child_to_delete" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete intermediate_child" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
  echo "delete grandchild_exception" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
}

# Ensure cleanup runs on exit
trap cleanup EXIT

# Test cases
tests_passed=0
tests_failed=0

# Pre-create items for clear_descendants tests
echo "add task -h parent_clear_desc -t 'Parent for clear descendants.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h child_clear_desc_1 -t 'Child 1.' -p parent_clear_desc" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h child_clear_desc_2 -t 'Child 2.' -p parent_clear_desc" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h grandchild_clear_desc_1 -t 'Grandchild 1.' -p child_clear_desc_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1


# Test 1: Successful clear descendants
if run_test "Successful clear descendants" "Succeeded" \
  "clear_descendants parent_clear_desc"; then
  ((tests_passed++))
  # Verify children are gone
  if echo "report handle child_clear_desc_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "not found"; then
    echo "PASS: Child 1 'child_clear_desc_1' no longer exists."
  else
    echo "FAIL: Child 1 'child_clear_desc_1' still exists."
    ((tests_failed++))
  fi
  if echo "report handle child_clear_desc_2" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "not found"; then
    echo "PASS: Child 2 'child_clear_desc_2' no longer exists."
  else
    echo "FAIL: Child 2 'child_clear_desc_2' still exists."
    ((tests_failed++))
  fi
  if echo "report handle grandchild_clear_desc_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "not found"; then
    echo "PASS: Grandchild 1 'grandchild_clear_desc_1' no longer exists."
  else
    echo "FAIL: Grandchild 1 'grandchild_clear_desc_1' still exists."
    ((tests_failed++))
  fi
else
  ((tests_failed++))
fi

# Test 2: Attempt to clear descendants of a non-existent item
if run_test "Clear descendants of non-existent item" "Command failed" \
  "clear_descendants non_existent_parent"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 3: Attempt to clear descendants of an item that has no children
# Pre-create a new item for this test
echo "add task -h no_children_parent -t 'Parent with no children.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
if run_test "Clear descendants of item with no children" "Succeeded" \
  "clear_descendants no_children_parent"; then
  ((tests_passed++))
else
  ((tests_failed++))
fi

# Test 4: Clear descendants with a single exception
echo "add task -h parent_exception_test -t 'Parent for exception test.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h child_exception_1 -t 'Child exception 1.' -p parent_exception_test" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h child_exception_2 -t 'Child exception 2.' -p parent_exception_test" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
if run_test "Clear descendants with single exception" "Succeeded" \
  "clear_descendants parent_exception_test:child_exception_1"; then
  ((tests_passed++))
  # Verify child_exception_1 still exists
  if echo "report handle child_exception_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "child_exception_1"; then
    echo "PASS: Child exception 1 'child_exception_1' still exists."
  else
    echo "FAIL: Child exception 1 'child_exception_1' was deleted."
    ((tests_failed++))
  fi
  # Verify child_exception_2 is gone
  if echo "report handle child_exception_2" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "not found"; then
    echo "PASS: Child exception 2 'child_exception_2' no longer exists."
  else
    echo "FAIL: Child exception 2 'child_exception_2' still exists."
    ((tests_failed++))
  fi
else
  ((tests_failed++))
fi

# Test 5: Clear descendants with multiple and nested exceptions
echo "add task -h grandchild_exception_1 -t 'Grandchild exception 1.' -p child_exception_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
if run_test "Clear descendants with multiple and nested exceptions" "Succeeded" \
  "clear_descendants parent_exception_test:child_exception_1:grandchild_exception_1"; then
  ((tests_passed++))
  # Verify child_exception_1 still exists
  if echo "report handle child_exception_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "child_exception_1"; then
    echo "PASS: Child exception 1 'child_exception_1' still exists."
  else
    echo "FAIL: Child exception 1 'child_exception_1' was deleted."
    ((tests_failed++))
  fi
  # Verify grandchild_exception_1 still exists
  if echo "report handle grandchild_exception_1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "grandchild_exception_1"; then
    echo "PASS: Grandchild exception 1 'grandchild_exception_1' still exists."
  else
    echo "FAIL: Grandchild exception 1 'grandchild_exception_1' was deleted."
    ((tests_failed++))
  fi
else
  ((tests_failed++))
fi

# Test 6: Clear descendants preserving the hierarchy for a nested exception
echo "add task -h parent_hierarchy_test -t 'Parent for hierarchy test.'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h child_to_delete -t 'Child to delete.' -p parent_hierarchy_test" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h intermediate_child -t 'Intermediate child.' -p parent_hierarchy_test" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
echo "add task -h grandchild_exception -t 'Grandchild exception.' -p intermediate_child" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" > /dev/null 2>&1
if run_test "Clear descendants preserving hierarchy for nested exception" "Succeeded" \
  "clear_descendants parent_hierarchy_test:grandchild_exception"; then
  ((tests_passed++))
  # Verify grandchild_exception still exists
  if echo "report handle grandchild_exception" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "grandchild_exception"; then
    echo "PASS: Grandchild exception 'grandchild_exception' still exists."
  else
    echo "FAIL: Grandchild exception 'grandchild_exception' was deleted."
    ((tests_failed++))
  fi
  # Verify intermediate_child still exists
  if echo "report handle intermediate_child" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "intermediate_child"; then
    echo "PASS: Intermediate child 'intermediate_child' still exists."
  else
    echo "FAIL: Intermediate child 'intermediate_child' was deleted."
    ((tests_failed++))
  fi
  # Verify child_to_delete is gone
  if echo "report handle child_to_delete" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" 2>&1 | grep -q "not found"; then
    echo "PASS: Child to delete 'child_to_delete' no longer exists."
  else
    echo "FAIL: Child to delete 'child_to_delete' still exists."
    ((tests_failed++))
  fi
else
  ((tests_failed++))
fi

# Final result
if [ $tests_failed -eq 0 ]; then
  echo -e "\nAll clear_descendants command E2E tests passed!"
  exit 0
else
  echo -e "\n$tests_failed clear_descendants command E2E test(s) failed."
  exit 1
fi
