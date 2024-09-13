#!/bin/bash

# Directory to watch
WATCH_DIR="src"

# Variable to store the PID of the gleam process
GLEAM_PID=""

# Function to run commands
run_commands() {
    echo "File changed. Running commands..."
    matcha
    
    # Kill the previous gleam process if it exists
    if [ ! -z "$GLEAM_PID" ]; then
        kill $GLEAM_PID 2>/dev/null
    fi
    
    # Run gleam in the background and store its PID
    gleam run &
    GLEAM_PID=$!
    
    echo "Gleam server started with PID: $GLEAM_PID"
}

# Run commands initially
run_commands

# Watch for changes
fswatch -o "$WATCH_DIR" | while read change
do
    run_commands
done