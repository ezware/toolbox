#!/bin/bash
echo "Removing added files"
git status | grep -v modified | grep '^[[:space:]]' | grep -v git | xargs rm -rf

echo "Restoring modified files"
git status | grep modified | awk '{print $2}' | xargs git checkout --
