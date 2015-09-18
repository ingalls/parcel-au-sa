#!/usr/bin/env bash

Q=$(echo $1 | sed 's/\\//g' | jq '.[0] | .[0]')
W=$(echo $1 | sed 's/\\//g' | jq '.[0] | .[1]')
E=$(echo $1 | sed 's/\\//g' | jq '.[1] | .[0]')
R=$(echo $1 | sed 's/\\//g' | jq '.[1] | .[1]')

# $1 Bounds [[UPPERLEFT], [LOWERRIGHT]]
# $2 Job #
# $3 Grid
# $4 Total Jobs

# Get Map Image
QUERY=$(echo \
    "http://maps.sa.gov.au/arcgis/rest/services/DPTIExtLandServices/PropertyLocationBrowser20/MapServer/export" \
    "?dynamicLayers=%5B%7B%22id%22%3A11%2C%22source%22%3A%7B%22type%22%3A%22mapLayer%22%2C%22mapLayerId%22%3A11%7D%2C%22drawingInfo%22%3A%7B%22renderer%22%3A%7B%22type%22%3A%22simple%22%2C%22symbol%22%3A%7B%22color%22%3A%5B145%2C145%2C145%2C51%5D%2C%22outline%22%3A%7B%22color%22%3A%5B0%2C0%2C0%2C51%5D%2C%22width%22%3A0.75%2C%22type%22%3A%22esriSLS%22%2C%22style%22%3A%22esriSLSSolid%22%7D%2C%22type%22%3A%22esriSFS%22%2C%22style%22%3A%22esriSFSSolid%22%7D%7D%7D%7D%2C%7B%22id%22%3A39%2C%22source%22%3A%7B%22type%22%3A%22mapLayer%22%2C%22mapLayerId%22%3A39%7D%2C%22drawingInfo%22%3A%7B%22renderer%22%3A%7B%22type%22%3A%22simple%22%2C%22symbol%22%3A%7B%22color%22%3A%5B145%2C145%2C145%2C51%5D%2C%22outline%22%3A%7B%22color%22%3A%5B0%2C0%2C0%2C51%5D%2C%22width%22%3A0.75%2C%22type%22%3A%22esriSLS%22%2C%22style%22%3A%22esriSLSSolid%22%7D%2C%22type%22%3A%22esriSFS%22%2C%22style%22%3A%22esriSFSSolid%22%7D%7D%7D%7D%5D" \
    "&dpi=96" \
    "&format=PNG32" \
    "&bbox=15384863.632720726%2C-3942146.7790148826%2C15385607.69941804%2C-3941911.4962871596" \
    "&bboxSR=3857" \
    "&imageSR=3857" \
    "&size=1246%2C394" \
    "&layers=show%3A11%2C39" \
    "&f=image" \
    | sed 's/ //g'
)

curl -s \
    -H 'Host: maps.sa.gov.au' \
    -H 'Referer: http://maps.sa.gov.au/plb/' \
    "$QUERY" > /tmp/au_${3}_${2}.png

exit

if [[ -z $(which md5sum) ]]; then
    gdal_translate -of GTiff -a_ullr $Q $W $E $R -a_srs 'EPSG:3857' /tmp/${4}_${3}.png /tmp/${4}_parcels/$(md5 -r /tmp/${4}_${3}.png | grep -Eo '.* ' | sed 's/ //g').tif
else
    gdal_translate -of GTiff -a_ullr $Q $W $E $R -a_srs 'EPSG:3857' /tmp/${4}_${3}.png /tmp/${4}_parcels/$(md5sum /tmp/${4}_${3}.png | grep -Eo '.* ' | sed 's/ //g').tif
fi

rm /tmp/${4}_${3}.*
echo "$3/$5"
