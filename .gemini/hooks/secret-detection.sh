#!/usr/bin/env bash
# Read the hook input (JSON)
input=$(cat)

# Extract tool name and the file path affected
tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only scan Swift files for now
if [[ "$file_path" == *.swift ]]; then
    echo "Scanning $file_path for hardcoded secrets..." >&2
    # Simple grep pattern for strings that look like Spotify client secrets
    # (Typically 32 hexadecimal characters)
    # Also look for the variable name itself.
    if grep -E 'SPOTIFY_API_CLIENT_SECRET\s*=\s*".+"' "$file_path" >/dev/null || 
       grep -E '"[a-f0-9]{32}"' "$file_path" >/dev/null; then
        echo "Error: Hardcoded secret detected in $file_path." >&2
        # Exit with 2 to block the result and show the error to the agent.
        echo '{"decision": "block", "message": "Possible hardcoded secret detected in '$file_path'. Use Config.xcconfig or AuthManager instead."}'
        exit 2
    fi
fi

# Always return a JSON object to stdout
echo '{"decision": "allow"}'
