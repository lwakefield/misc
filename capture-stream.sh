#!/bin/bash

cleanup() {
    echo "Received SIGINT. Cleaning up..."
    pkill -P "$$"                            # Kill all child processes
    echo "Cleanup complete. Exiting."
    exit 1
}
trap 'cleanup' SIGINT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            target="$2"
            shift 2  # Consume both the option and its value
            ;;
        --name-fmt)
            name_fmt="$2"
            shift 2  # Consume both the option and its value
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$target" ] || [ -z "$name_fmt" ]; then
    echo "Missing required arguments."
    exit 1
fi

archive_n_cleanup () {
    echo "uploading $1..."
    (ia upload $(basename $1) $1 && rm -r $(dirname $1) && echo "done uploading + cleaning up $1...")  || echo "error uploading $1..."
}

# we are streaming in 6h chunks, where chunks always finish on a 6h boundary (eg. 12a 6a 12p 6p)
while true; do
    # 00 - open the stream ASAP
    d=$(mktemp -d)
    f=$d/$(printf $name_fmt $(date +"%Y-%m-%dT%H-%M-%S-%Z"))

    curl -s $target > $f & curl_pid=$!

    # 01 - work out how long to stream for until the next chunk
    current_time=$(date +%s)
    next_block=$((current_time - (current_time % (6 * 3600)) + 6 * 3600))         # Calculate when the next 6-hour block starts
    seconds_until_next_block=$((next_block - current_time))                       # Calculate the number of seconds until the next 6-hour block
    echo "capturing $f for $(date -u -d "@$seconds_until_next_block" '+%Hh %Mm %Ss')..."

    sleep $seconds_until_next_block
    kill $curl_pid
    tail --pid=$curl_pid -f /dev/null

    # 02 - fire n' forget so we can start capturing the next stream
    archive_n_cleanup $f &
done
