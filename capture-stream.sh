#!/bin/bash

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            target="$2"
            shift 2  # Consume both the option and its value
            ;;
        --output)
            output="$2"
            shift 2  # Consume both the option and its value
            ;;
        --duration)
            hours=$(echo "$2" | grep -oE '[0-9]+h' | sed 's/h//')
            minutes=$(echo "$2" | grep -oE '[0-9]+m' | sed 's/m//')
            seconds=$(echo "$2" | grep -oE '[0-9]+s' | sed 's/s//')
            duration=$((hours * 3600 + minutes * 60 + seconds))
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$target" ] || [ -z "$output" ] || [ -z "$duration" ]; then
    echo "Missing required arguments."
    exit 1
fi

curl $target > $output & pid=$!

sleep $duration
kill $pid
tail --pid=$pid -f /dev/null

ia upload $output $output --metadata="title=$output"