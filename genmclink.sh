jsonfile="mcsurfacegr.json"
based=`base64 -w0 $jsonfile`
echo "https://mapcomplete.osm.be?userlayout=true#$based"
firefox "https://mapcomplete.osm.be?userlayout=true#$based"

