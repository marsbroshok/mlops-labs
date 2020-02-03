#!/bin/bash


err_handler() {
    echo "Error on line: $1"
    echo "Caused by: $2"
    echo "That returned exit status: $3"
    echo "Aborting..."
    exit $3
}

trap 'err_handler "$LINENO" "$BASH_COMMAND" "$?"' ERR

if [[ 1 ]]; then
    cd ~/ttt 
else
    echo Hello
fi

ls -la ~/projects