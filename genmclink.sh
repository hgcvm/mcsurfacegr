jsonfile="mcsurfacegr.json"
based=`base64 -w0 $jsonfile`
firefox "https://mapcomplete.osm.be?userlayout=true#$based"

