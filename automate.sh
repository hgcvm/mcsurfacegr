#!/bin/bash

OVERPASSAPIINSTANCE="https://overpass.kumi.systems/api/interpreter"
#OVERPASSAPIINSTANCE="https://maps.mail.ru/osm/tools/overpass/api/interpreter"
#OVERPASSAPIINSTANCE="https://z.overpass-api.de/api/interpreter"

# 1 Dowload and convert all relations from merge/ dir. Write to data/ dir.
INPUT=`cat merge/* | sed 's/[ \t]*$//' | sort -n | uniq`
TOTALCOUNT=`wc -w <<< $INPUT` && COUNTER=0
for REL in $INPUT; do
	# Get osm file from overpass for each relation, and convert to geojson
	wget -qO data/$REL.osm "$OVERPASSAPIINSTANCE?data=rel($REL);way(r)[\"highway\"];out geom;"
	osmtogeojson data/$REL.osm > data/$REL.geojson

	# Sleep, rate limit queries overpass server
#	sleep 3

	# Show some output
	let COUNTER=COUNTER+1 
	printf "Downloading & convert - ($COUNTER/$TOTALCOUNT) $REL\n"
done
printf "Downloading & convert - DONE\n"


# 2 Merge child relations. Superrelations are defined as files in the merge/ dir. Write result in data/dir
INPUT=`find ./merge/ -type f -printf "%f\n"`
TOTALCOUNT=`wc -l <<< $INPUT` && COUNTER=0
while read REL; do
        readarray -t RELCHILDR < merge/"$REL"
        	#Add dir and extension to array members, so geojson-merge can use array as input files
	        for ((i=0; i < ${#RELCHILDR[@]}; i++)); do
        	        RELCHILDR[$i]=`echo ${RELCHILDR[$i]} | sed 's/[ \t]*$//'`  # removes trailing space
        	        RELCHILDR[$i]=`sed 's_^_./data/_' <<< ${RELCHILDR[$i]}`
                	RELCHILDR[$i]=`sed 's_$_.geojson_' <<< ${RELCHILDR[$i]}`
	        done
	        geojson-merge ${RELCHILDR[@]} > data/"$REL".geojson

	# Calculate the percentage of completion: "ways with surface tags" / "all ways". Store this in a variable
	HASSURFACE=`grep -i '"surface":' data/"$REL".geojson | grep -c -vi 'paved",'`
	TOTALWAYS=`grep -ic '"highway":' data/"$REL".geojson`
	PERCENTAGE=`printf %.0f "$((10**3 * 100 * $HASSURFACE/$TOTALWAYS))e-3"`
	SUMPERCENTAGE=`expr $SUMPERCENTAGE + $PERCENTAGE`	

        # Create part of html table
	printf '%s\n' "<tr><td>$PERCENTAGE%</td><td><a href=\"https://mapcomplete.org/theme?z=9&lat=50.70689&lon=4.295654&userlayout=https://raw.githubusercontent.com/hgcvm/mcsurfacegr/main/data/$REL.json\">$REL</a></td></tr>" >> temp_table.html

	#3 Generate MapComplete JSON.
	cp mcsurfacegr.json data/"$REL".json
	sed -i "s_githubusercontent.com/hgcvm/mcsurfacegr/main/test-export.geojson_githubusercontent.com/hgcvm/mcsurfacegr/main/data/$REL.geojson_" data/"$REL".json

        # Show some output
        let COUNTER=COUNTER+1
	printf "Merging geojson, generate json - ($COUNTER/$TOTALCOUNT) $REL\n"
done < <(echo "$INPUT")
printf "Merging geojson, generate json - DONE\n"


# 3 Calculate average completion percentage
TOTALFORAVG=`find ./merge/ -type f | wc -l`
GEMIDDELDPERC=`printf "%.0f" $(echo "$SUMPERCENTAGE / $TOTALFORAVG" | bc)`


# 4 Generate new HTML file
echo '<!DOCTYPE html> <html lang="nl"> <head> <title> Grote Routepaden Mapcomplete themes</title> <style> td {border-left:1px solid black; border-top:1px solid black;} table {border-right:1px solid black; border-bottom:1px solid black;} </style> </head> <body> <table>' > html/overview.html
sort -t\< -k5 temp_table.html >> html/overview.html
echo "<tr><td>$GEMIDDELDPERC%</td><td>Gemiddeld</td></table><br><br>" >> html/overview.html
echo '<b>Kwaliteitscontrole</b><br><a href="https://mapcomplete.org/?mode=statistics&filter-theme-search=%7B%22search%22%3A%22hgcvm%22%7D&filter-theme-search-search=hgcvm">Mapcomplete statistics</a><br><a href="https://osmcha.org/?aoi=959b2cad-4737-4d98-a644-c2fc80dad1d6">Osmcha filter</a><br>' >> html/overview.html
echo -n 'Laatste update: '>> html/overview.html && TZ='Europe/Brussels' date >> html/overview.html && echo '<br>Vragen of opmerking welkom via een <a href=https://www.openstreetmap.org/message/new/s8evq>OpenStreetMap bericht</a></body></html>' >> html/overview.html
echo Generating HTML


# 5 Deleting merged geojson files and cleanup
INPUT=`cat merge/* | sed 's/[ \t]*$//' | sort -n | uniq`
TOTALCOUNT=`wc -w <<< $INPUT` && COUNTER=0
for REL in $INPUT; do
	rm data/$REL.geojson

	# Show some output
	let COUNTER=COUNTER+1 
	printf "Deleting merged geojson files - ($COUNTER/$TOTALCOUNT) $REL\n"
done
printf "Deleting merged geojson files - DONE\n"
rm temp_table.html
rm data/*.osm
echo Done
