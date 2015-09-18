#!/usr/bin/env bash

if [ -z $1 ]; then
    echo "./run <GRID #>"
    exit 1
fi
GRID=$1
OLDIFS=$IFS

echo "ok - Setting up build environment"
mkdir -p /tmp/au_${GRID}_parcels/
rm -f /tmp/au_${GRID}_parcels/* 

rm /tmp/au_${GRID}_bounds
echo "ok - tiling grid polygon"
while IFS='' read -r line || [[ -n $line ]]; do
    TOPRIGHT=$(echo $line   | jq -r -c '.geometry | .coordinates | .[] | .[]' | sed '2!d')
    BOTTOMLEFT=$(echo $line | jq -r -c '.geometry | .coordinates | .[] | .[]' | sed '4!d')
    echo "[$TOPRIGHT, $BOTTOMLEFT]" >> /tmp/au_${GRID}_bounds
done <<< "$( $(dirname $0)/util/cover.js "$(awk "NR==${GRID}" ./util/grids.geojson | jq '.geometry')" | jq -r -c '.features | .[]')"

echo "ok - Beginning Download ($(wc -l /tmp/au_${GRID}_bounds | grep -Eo "[0-9]+") tiles)"
PROG_TOT=$(wc -l /tmp/au_${GRID}_bounds | grep -Eo "[0-9]+")
cat /tmp/au_${GRID}_bounds | parallel --gnu "$(dirname $0)/util/getImage.sh \"{}\" \"{#}\" \"$GRID\" \"${PROG_TOT}\""

exit

rm /tmp/au_${GRID}_bounds

echo "ok - merging parcels"
gdal_merge.py -init 255 -o /tmp/${GRID}_parcel_out.tif /tmp/${GRID}_parcels/*.tif
rm -rf /tmp/${GRID}_parcels/

echo "ok - standarize image"
convert /tmp/${GRID}_parcel_out.tif \
    \( -alpha remove \) \
    \( -fill black -opaque white \) \
    TIFF64:/tmp/${GRID}_parcel_clean.tif

echo "ok - set projection"
./util/gdalcopyproj.py /tmp/${GRID}_parcel_out.tif /tmp/${GRID}_parcel_clean.tif
rm /tmp/${GRID}_parcel_out.tif

echo "ok - gdal_polygonize"
gdal_polygonize.py -nomask /tmp/${GRID}_parcel_clean.tif -f "ESRI Shapefile" /tmp/${GRID}_parcel_tile.shp
rm /tmp/${GRID}_parcel_clean.tif

echo "ok - reproject to 4326"
# Polygonize will be as 54004 even though it is actually 3857
ogr2ogr /tmp/${GRID}_parcel_out.geojson /tmp/${GRID}_parcel_tile.shp -s_srs EPSG:3857 -t_srs EPSG:4326 -f "GeoJSON"
rm /tmp/${GRID}_parcel_tile.*

echo "ok - filter by black"
echo '{ "type": "FeatureCollection", "features": [' > /tmp/${GRID}_parcel_pts.geojson.tmp
grep "DN\": 0" /tmp/${GRID}_parcel_out.geojson >> /tmp/${GRID}_parcel_pts.geojson.tmp
sed -i '$s/,$//' /tmp/${GRID}_parcel_pts.geojson.tmp
echo ']}' >> /tmp/${GRID}_parcel_pts.geojson.tmp

echo "ok - poly => pt"
./node_modules/turf-cli/turf-point-on-surface.js /tmp/${GRID}_parcel_pts.geojson.tmp > /tmp/${GRID}_parcel_pts.geojson
rm /tmp/${GRID}_parcel_pts.geojson.tmp


jq -r -c '.features | .[] | .geometry | .coordinates' /tmp/${GRID}_parcel_pts.geojson > /tmp/${GRID}_coords
PROG_TOT=$(wc -l /tmp/${GRID}_parcel_pts.geojson | grep -Po '\d+')
rm /tmp/${GRID}_parcel_pts.geojson

echo "LNG,LAT,STR,DISTRICT,REGION" > ${GRID}_out.csv
cat /tmp/${GRID}_coords | parallel -j1 --gnu "./util/getAddress.sh \"{}\" \"{#}\" \"$PROG_TOT\" \"$GRID\""
rm /tmp/${GRID}_coords
