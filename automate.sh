#!/bin/bash
CSV_FN="GR_GPX_RelationID.csv"
COUNTER=0
TOTALRELATIONS=`awk -F , '{print $3 }' $CSV_FN | uniq | sed '/OSM relation ID/d' | sed '/not mapped yet/d' | wc -l`

while read REL; do 

	# Get osm file from overpass for each relation, and convert to geojson
	wget -qO data/r$REL.osm "https://maps.mail.ru/osm/tools/overpass/api/interpreter?data=rel($REL);way(r)[\"highway\"];out geom;"
	osmtogeojson data/r$REL.osm > data/r$REL.geojson

	# Take a copy of the skeleton file mcsurfacegr.json, rename it to unique relationid.json and change everything inside to point to the relation
	cp mcsurfacegr.json data/r$REL.json
	sed -i "s_githubusercontent.com/hgcvm/mcsurfacegr/main/test-export.geojson_githubusercontent.com/hgcvm/mcsurfacegr/main/data/r$REL.geojson_" data/r$REL.json

	# Calculate the percentage of completion: "ways with surface tags" / "all ways". Store this in a variable
	HASSURFACE=`grep -i '"surface":' data/r$REL.geojson | grep -c -vi 'paved",'`
	TOTALWAYS=`grep -ic '"highway":' data/r$REL.geojson`
	PERCENTAGE=`printf %.0f "$((10**3 * 100 * $HASSURFACE/$TOTALWAYS))e-3"`
	SUMPERCENTAGE=`expr $SUMPERCENTAGE + $PERCENTAGE`	

	#Create a new CSV file, with 1 human readable route name, 2 OSM relation ID, 3 percentage completed (later used to generate HTML)
	grep $REL $CSV_FN | awk -F , -v percentage=$PERCENTAGE -v rel=$REL '{print $1";"rel";"percentage}' >> tmp.csv

	# Show some output
	let COUNTER=COUNTER+1 
	echo "$REL - ($COUNTER/$TOTALRELATIONS)"

	# Sleep, rate limit queries overpass server
	# sleep 3

	#use a list of relations to loop over
done < <(awk -F , '{print $3 }' $CSV_FN | uniq | sort -g | sed '/OSM relation ID/d' | sed '/not mapped yet/d')

#Calculate average completion percentage
GEMIDDELDPERC=`printf "%.0f" $(echo "$SUMPERCENTAGE / $TOTALRELATIONS" | bc)`

#generate new HTML file
echo '<!DOCTYPE html> <html lang="nl"> <head> <title> Grote Routepaden Mapcomplete themes</title> <style> td {border-left:1px solid black; border-top:1px solid black;} table {border-right:1px solid black; border-bottom:1px solid black;} </style> </head> <body> <table>' > html/overview.html
sort -g tmp.csv | awk -F ";" '{print "<tr><td>"$2"</td><td>"$3"%</td><td><a href=\"https://mapcomplete.osm.be?z=9&lat=50.70689&lon=4.295654&userlayout=https://raw.githubusercontent.com/hgcvm/mcsurfacegr/main/data/r"$2".json\">"$1"</a></td></tr>"}' >> html/overview.html
echo "<tr><td>Gemiddeld</td><td>$GEMIDDELDPERC%</td><td></td></table><br><br>" >> html/overview.html
echo '<b>Kwaliteitscontrole</b><br><a href="https://mapcomplete.osm.be/?mode=statistics&filter-theme-search=%7B%22search%22%3A%22hgcvm%22%7D&filter-theme-search-search=hgcvm">Mapcomplete statistics</a><br><a href="https://osmcha.org/?aoi=959b2cad-4737-4d98-a644-c2fc80dad1d6">Osmcha filter</a><br>' >> html/overview.html
echo -n 'Laatste update: '>> html/overview.html && TZ='Europe/Brussels' date >> html/overview.html && echo '<br>Vragen of opmerking welkom via een <a href=https://www.openstreetmap.org/message/new/s8evq>OpenStreetMap bericht</a></body></html>' >> html/overview.html

# cleanup
rm data/r*.osm
rm tmp.csv
echo done
