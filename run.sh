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

if [ ! -f /tmp/au_${GRID}_bounds ]; then
    echo "ok - tiling grid polygon"
    while IFS='' read -r line || [[ -n $line ]]; do
        TOPRIGHT=$(echo $line   | jq -r -c '.geometry | .coordinates | .[] | .[]' | sed '2!d')
        BOTTOMLEFT=$(echo $line | jq -r -c '.geometry | .coordinates | .[] | .[]' | sed '4!d')
        echo "[$TOPRIGHT, $BOTTOMLEFT]" >> /tmp/au_${GRID}_bounds
    done <<< "$( $(dirname $0)/util/cover.js "$(awk "NR==${GRID}" ./util/grids.geojson | jq '.geometry')" | jq -r -c '.features | .[]')"
else
    echo "ok - using cached grid"
fi

echo "ok - Beginning Download ($(wc -l /tmp/au_${GRID}_bounds | grep -Eo -m 1 "[0-9]+" | head -1) tiles)"
PROG_TOT=$(wc -l /tmp/au_${GRID}_bounds | grep -Eo "[0-9]+" | head -1)
cat /tmp/au_${GRID}_bounds | parallel --gnu "$(dirname $0)/util/getImage.sh \"{}\" \"{#}\" \"$GRID\" \"${PROG_TOT}\""
rm /tmp/au_${GRID}_bounds

echo "ok - merging parcels"
gdal_merge.py -init 255 -o /tmp/au_${GRID}_parcel_out.tif /tmp/au_${GRID}_parcels/*.tif
rm -rf /tmp/au_${GRID}_parcels/

echo "ok - gdal_polygonize"
gdal_polygonize.py -nomask /tmp/au_${GRID}_parcel_out.tif -f "ESRI Shapefile" /tmp/au_${GRID}_parcel_tile.shp
rm /tmp/au_${GRID}_parcel_out.tif

echo "ok - reproject to 4326"
# Polygonize will be as 54004 even though it is actually 3857
ogr2ogr /tmp/au_${GRID}_parcel_out.geojson /tmp/au_${GRID}_parcel_tile.shp -s_srs EPSG:3857 -t_srs EPSG:4326 -f "GeoJSON"

echo "ok - filter by parcel fill"
echo '{ "type": "FeatureCollection", "features": [' > /tmp/au_${GRID}_parcel_pts.geojson.tmp
grep "DN\": 232" /tmp/au_${GRID}_parcel_out.geojson >> /tmp/au_${GRID}_parcel_pts.geojson.tmp
sed -i '$s/,$//' /tmp/au_${GRID}_parcel_pts.geojson.tmp
echo ']}' >> /tmp/au_${GRID}_parcel_pts.geojson.tmp

echo "ok - poly => pt"
./node_modules/turf-cli/turf-point-on-surface.js /tmp/au_${GRID}_parcel_pts.geojson.tmp > /tmp/au_${GRID}_parcel_pts.geojson
rm /tmp/au_${GRID}_parcel_pts.geojson.tmp

jq -r -c '.features | .[] | .geometry | .coordinates' /tmp/au_${GRID}_parcel_pts.geojson > /tmp/au_${GRID}_coords
PROG_TOT=$(wc -l /tmp/au_${GRID}_coords | grep -Po '\d+' | head -1)
rm /tmp/au_${GRID}_parcel_pts.geojson

cat /tmp/au_${GRID}_coords | parallel -j1 --gnu "./util/getAddress.sh \"{}\" \"{#}\" \"$PROG_TOT\" \"$GRID\""

echo "{ \"type\": \"FeatureCollection\", \"features\": [" > out/au_${GRID}.geojson
sort /tmp/au_final_${GRID}.geojson | uniq >> out/au_${GRID}.geojson
sed -i '$s/,$//' out/au_${GRID}.geojson
echo "]}" >> out/au_${GRID}.geojson

rm /tmp/au_${GRID}_coords
