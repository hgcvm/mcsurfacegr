#!/bin/bash

#1 Dowload and convert all relations from CSV. Write to data/dir
CSV_FN="GR_GPX_RelationID.csv"
INPUT=`awk -F , '{print $3 }' $CSV_FN | uniq | sed '/OSM relation ID/d' | sed '/not mapped yet/d'`
TOTALCOUNT=`wc -w <<< $INPUT` && COUNTER=0
TOTALFORAVG=$TOTALCOUNT
for REL in $INPUT; do
	# Get osm file from overpass for each relation, and convert to geojson
	wget -qO data/$REL.osm "https://maps.mail.ru/osm/tools/overpass/api/interpreter?data=rel($REL);way(r)[\"highway\"];out geom;"
	osmtogeojson data/$REL.osm > data/$REL.geojson
	rm data/$REL.osm

	# Sleep, rate limit queries overpass server
	# sleep 3

	# Calculate the percentage of completion: "ways with surface tags" / "all ways". Store this in a variable
	HASSURFACE=`grep -i '"surface":' data/$REL.geojson | grep -c -vi 'paved",'`
	TOTALWAYS=`grep -ic '"highway":' data/$REL.geojson`
	PERCENTAGE=`printf %.0f "$((10**3 * 100 * $HASSURFACE/$TOTALWAYS))e-3"`
	SUMPERCENTAGE=`expr $SUMPERCENTAGE + $PERCENTAGE`	


	# Create part of html table
	HUMANNAME=$(grep $REL $CSV_FN | awk -F , '{print $1}')
	printf '%s\n' "<tr><td>$REL</td><td>$PERCENTAGE%</td><td><a href=\"https://mapcomplete.osm.be?z=9&lat=50.70689&lon=4.295654&userlayout=https://raw.githubusercontent.com/hgcvm/mcsurfacegr/main/data/$REL.json\">$HUMANNAME</a></td></tr>" >> temp_table.html

	# Show some output
	let COUNTER=COUNTER+1 
	echo "Downloading & convert $REL - ($COUNTER/$TOTALCOUNT)"
done


#2 For superrelations, merge the child relations. Superrelations are defined as files in the merge/ dir. Write result in data/dir
INPUT=`find ./merge/ -type f -printf "%f\n"`
TOTALCOUNT=`wc -w <<< $INPUT` && COUNTER=0
for REL in $INPUT; do
        readarray -t RELCHILDR < merge/$REL
        for ((i=0; i < ${#RELCHILDR[@]}; i++)); do
		#remove each child relation from temp_table.html
		sed -i "/${RELCHILDR[$i]}/d" temp_table.html
		#Add dir and extension to array members, so geojson-merge can use array as input files
		RELCHILDR[$i]=`sed 's_^_./data/_' <<< ${RELCHILDR[$i]}`
                RELCHILDR[$i]=`sed 's_$_.geojson_' <<< ${RELCHILDR[$i]}`
        done

        geojson-merge ${RELCHILDR[@]} > data/$REL.geojson

	#removing geojson files of child relations
        for ((i=0; i < ${#RELCHILDR[@]}; i++)); do
		rm ${RELCHILDR[$i]}
	done

	# Create part of html table
	HUMANNAME=$REL
	printf "<tr><td>...</td><td>...</td><td><a href=\"https://mapcomplete.osm.be?z=9&lat=50.70689&lon=4.295654&userlayout=https://raw.githubusercontent.com/hgcvm/mcsurfacegr/main/data/$REL.json\">$HUMANNAME</a></td></tr>\n" >> temp_table.html


        # Show some output
        let COUNTER=COUNTER+1
        echo "Merging geojson $REL - ($COUNTER/$TOTALCOUNT)"
done


#3 Generate MapComplete JSON, do some calculations and CSV as source for HTML
INPUT=`find ./data/*.geojson  -printf "%f\n" | sed 's/\.geojson//'`
TOTALCOUNT=`wc -w <<< $INPUT` && COUNTER=0
for REL in $INPUT; do
	# Take a copy of the skeleton file mcsurfacegr.json, rename it to unique relationid.json and change everything inside to point to the relation
	cp mcsurfacegr.json data/$REL.json
	sed -i "s_githubusercontent.com/hgcvm/mcsurfacegr/main/test-export.geojson_githubusercontent.com/hgcvm/mcsurfacegr/main/data/$REL.geojson_" data/$REL.json

	# Show some output
	let COUNTER=COUNTER+1 
	echo "Generating json $REL - ($COUNTER/$TOTALCOUNT)"
done

#Calculate average completion percentage
GEMIDDELDPERC=`printf "%.0f" $(echo "$SUMPERCENTAGE / $TOTALFORAVG" | bc)`

#generate new HTML file
echo '<!DOCTYPE html> <html lang="nl"> <head> <title> Grote Routepaden Mapcomplete themes</title> <style> td {border-left:1px solid black; border-top:1px solid black;} table {border-right:1px solid black; border-bottom:1px solid black;} </style> </head> <body> <table>' > html/overview.html
cat temp_table.html >> html/overview.html
echo "<tr><td>Gemiddeld</td><td>$GEMIDDELDPERC%</td><td></td></table><br><br>" >> html/overview.html
echo '<b>Kwaliteitscontrole</b><br><a href="https://mapcomplete.osm.be/?mode=statistics&filter-theme-search=%7B%22search%22%3A%22hgcvm%22%7D&filter-theme-search-search=hgcvm">Mapcomplete statistics</a><br><a href="https://osmcha.org/?aoi=959b2cad-4737-4d98-a644-c2fc80dad1d6">Osmcha filter</a><br>' >> html/overview.html
echo -n 'Laatste update: '>> html/overview.html && TZ='Europe/Brussels' date >> html/overview.html && echo '<br>Vragen of opmerking welkom via een <a href=https://www.openstreetmap.org/message/new/s8evq>OpenStreetMap bericht</a></body></html>' >> html/overview.html

# cleanup
rm temp_table.html
echo done
