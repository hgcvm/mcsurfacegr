#!/bin/bash
rm html/overview.html

CSV_FN="GR_GPX_RelationID.csv"

cut -d, -f2 --complement $CSV_FN > tmp.csv
sed -i '/OSM relation ID/d' tmp.csv
sed -i '/not mapped yet/d' tmp.csv
gawk -i inplace -F, '{print "<a href=\"https://mapcomplete.osm.be?userlayout=https://raw.githubusercontent.com/hgcvm/mcsurfacegr/main/data/r"$2".json\">"$1"</a>,"$2}' tmp.csv 

echo "<table>" >> html/overview.html
sed -e 's/^/<tr><td>/' -e 's/,/<\/td><td>/g' -e 's/$/<\/td><\/tr>/' tmp.csv >> html/overview.html
echo "</table>" >> html/overview.html

rm tmp.csv
