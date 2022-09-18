#!/bin/bash
awk -F , '{print $3}' GR_GPX_RelationID.csv > relations
#sort -g relations -o relations
sed -i '/OSM relation ID/d' relations
sed -i '/not mapped yet/d' relations

while read REL; do 
wget -qO data/r$REL.osm "https://overpass-api.de/api/interpreter?data=rel($REL);way(r)[\"highway\"];out geom;"
osmtogeojson data/r$REL.osm > data/r$REL.geojson
rm data/r$REL.osm
cp mcsurfacegr.json data/r$REL.json
sed -i "s_githubusercontent.com/hgcvm/mcsurfacegr/main/export.geojson_githubusercontent.com/hgcvm/mcsurfacegr/main/data/r$REL.geojson_" data/r$REL.json
echo $REL
done <relations
echo done

