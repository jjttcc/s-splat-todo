#!/bin/bash

# Test for recursive report generation with indentation

# Exit immediately if a command exits with a non-zero status.
set -e

# Set up environment
basedir="$(dirname $0)"
export STODO_CLIENT_REPL=$basedir/../../src/stodo_client_repl
#export STODO_CLIENT_REPL="src/stodo_client_repl"
export USER_ID="test_user_$$_$$"
export APP_NAME="test_app_$$_$$"

# Function to clean up test data
cleanup() {
  echo "Cleaning up..."
  echo "delete task-parent" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME"
  echo "delete task-child-1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME"
  echo "delete task-child-2" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME"
  echo "delete task-grandchild-1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME"
  rm -f "$actual_output_file"
}

trap cleanup EXIT

# Create a hierarchy of items
echo "add task -h task-parent -t 'Parent Task'" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME"

echo "add task -h task-child-1 -t 'Child Task 1' -p task-parent" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME"

echo "add task -h task-child-2 -t 'Child Task 2' -p task-parent" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME"

echo "add task -h task-grandchild-1 -t 'Grandchild Task 1' -p task-child-1" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME"

# Run the recursive report and capture output
actual_output_file=$(mktemp)
# If the report formatting changes (e.g., indentation, field order, newlines),
# the oracle file 'test/e2e/oracle_recursive_report.txt' must be updated.
# To update: run the commands in the 'Create a hierarchy of items' section,
# then run the report command and redirect its output to the oracle file:
# echo "report complete -r handle:task-parent" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" | sed -e "s/^> //g" > test/e2e/oracle_recursive_report.txt
oracle_file="$basedir/oracle_recursive_report.txt"

echo "report complete -r handle:task-parent" | "$STODO_CLIENT_REPL" "$USER_ID" "$APP_NAME" | sed -e "s/^> //g" > "$actual_output_file"

# Compare outputs
if diff -u "$oracle_file" "$actual_output_file"; then
  echo "Recursive report test passed!"
  exit 0
else
  echo "Recursive report test failed! Differences found:"
  exit 1
fi
