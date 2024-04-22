#!/bin/bash

validate_version() {
    local version="$1"
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Format of version number is invalid. Please use the format x.y.z"
        exit 1
    fi
}

validate_app_name() {
    local app_name="$1"
    clean_name=$(echo "$app_name" | tr -cd '[:alnum:]_')
    if [[ "$clean_name" != "$app_name" ]]; then
        echo "Error: The application name can only contain letters, numbers, and underscores."
        exit 1
    fi
    if ! [[ "$app_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Error: The application name must start with a letter and can only contain letters, numbers, and underscores."
        exit 1
    fi
}
