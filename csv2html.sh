#!/bin/bash
# Source: https://gist.github.com/jschaub30/c67cf9e214d83accd4db

CSV_FN="GR_GPX_RelationID.csv"

cut -d, -f2 --complement $CSV_FN > tmp.csv
sed -i '/OSM relation ID/d' tmp.csv
sed -i '/not mapped yet/d' tmp.csv
gawk -i inplace -F, '{print "<a href=\"https://mapcomplete.osm.be?userlayout=https://raw.githubusercontent.com/hgcvm/mcsurfacegr/main/data/r"$2".json\">"$1"</a>,"$2}' tmp.csv 

echo "<table>"
head -n 1 tmp.csv | \
    sed -e 's/^/<tr><th>/' -e 's/,/<\/th><th>/g' -e 's/$/<\/th><\/tr>/'
tail -n +2 tmp.csv | \
    sed -e 's/^/<tr><td>/' -e 's/,/<\/td><td>/g' -e 's/$/<\/td><\/tr>/'
echo "</table>"

rm tmp.csv
