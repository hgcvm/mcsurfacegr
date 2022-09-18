#!/bin/bash
# Source: https://gist.github.com/jschaub30/c67cf9e214d83accd4db

[[ $# -ne 1 ]] && echo Usage: $0 [CSV_FN] && exit -1

CSV_FN=$1

echo "<table>"
head -n 1 $CSV_FN | \
    sed -e 's/^/<tr><th>/' -e 's/,/<\/th><th>/g' -e 's/$/<\/th><\/tr>/'
tail -n +2 $CSV_FN | \
    sed -e 's/^/<tr><td>/' -e 's/,/<\/td><td>/g' -e 's/$/<\/td><\/tr>/'
echo "</table>"
