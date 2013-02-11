#!/bin/bash
# for test
num=$(($RANDOM % 10))
echo "Start main process: args=$*, num=${num}"
sleep ${num}
echo "End main process.: args=$*, num=${num}"
#exit 1
