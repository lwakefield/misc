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
        --ia-args)
            ia_args="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

IFS=' ' read -ra ia_args <<< "$ia_args"

if [ -z "$target" ] || [ -z "$output" ] || [ -z "$duration" ]; then
    echo "Missing required arguments."
    exit 1
fi

mkfifo curlout-$output.pipe
curl $target > curlout-$output.pipe & pid1=$!
ia upload $output - --remote-name=$output --metadata="title:$output" "${ia_args[@]}" < curlout-$output.pipe & pid2=$!

sleep $duration
kill $pid1
tail --pid=$pid1 -f /dev/null
tail --pid=$pid2 -f /dev/null
rm curlout-$output.pipe