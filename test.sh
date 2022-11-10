#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then  # Mac OSX
    cmd=.build/apple/Products/Release/{{ tmplr.repo_name }}
else
    cmd=.build/release/{{ tmplr.repo_name }}
fi
file=.build/checkouts/XcodeProjKit/

if [[ ! -f "$cmd" ]]
then
    ./build.sh
fi

exitStatus=0

# 
$cmd $file
status=$?

if [ "$status" -eq "0" ]
then
    echo "✅ "
else
    echo "🚫 $status"
    exitStatus=1
fi

exit $exitStatus
