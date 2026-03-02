#!/usr/bin/env bash
# Read the hook input (JSON)
input=$(cat)

# Extract tool name and the file path affected
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only run for Swift files or if tool input suggests a write/replace
if [[ "$file_path" == *.swift ]]; then
    echo "Validating build after change to $file_path..." >&2
    # Run build in a quiet mode, just checking for errors.
    # We use -destination to target a simulator for speed.
    xcodebuild build -project "Music Stats iOS.xcodeproj" -scheme "Music Stats iOS" -destination 'platform=iOS Simulator,name=iPhone 15' -quiet >&2
    
    if [ $? -ne 0 ]; then
        echo "Error: Build failed after change to $file_path." >&2
        # Exit with 2 to block the result and show the error to the agent.
        echo '{"decision": "block", "message": "Build failed after changes. Please fix errors."}'
        exit 2
    fi
fi

# Always return a JSON object to stdout
echo '{"decision": "allow"}'
