#!/usr/bin/env bash
# Read the hook input (JSON)
input=$(cat)

# Extract tool name
tool_name=$(echo "$input" | jq -r '.tool_name')

# Only run for tools that perform build or test actions
if [[ "$tool_name" == "BuildProject" || "$tool_name" == "RunAllTests" ]]; then
    echo "Checking for valid Config.xcconfig..." >&2
    CONFIG_FILE="Music Stats iOS/Music Stats iOS/Config.xcconfig"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config.xcconfig is missing." >&2
        echo '{"decision": "block", "message": "Config.xcconfig is missing. Duplicate Sample.xcconfig to Config.xcconfig and fill in credentials."}'
        exit 2
    fi
    
    # Check for required keys
    REQUIRED_KEYS=("SPOTIFY_API_CLIENT_ID" "SPOTIFY_API_CLIENT_SECRET" "REDIRECT_URI_SCHEME" "REDIRECT_URI_HOST")
    for key in "${REQUIRED_KEYS[@]}"; do
        if ! grep -q "$key" "$CONFIG_FILE"; then
            echo "Error: Required key $key is missing from Config.xcconfig." >&2
            echo '{"decision": "block", "message": "Required key '$key' is missing from Config.xcconfig."}'
            exit 2
        fi
    done
fi

# Always return a JSON object to stdout
echo '{"decision": "allow"}'
