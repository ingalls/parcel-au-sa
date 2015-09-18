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
    "&bbox=$Q%2C$R%2C$E%2C$W" \
    "&bboxSR=3857" \
    "&imageSR=3857" \
    "&size=512%2C512" \
    "&layers=show%3A11%2C39" \
    "&f=image" \
    | sed 's/ //g'
)

curl -s \
    -H 'Host: maps.sa.gov.au' \
    -H 'Referer: http://maps.sa.gov.au/plb/' \
    "$QUERY" > /tmp/au_${3}_${2}.png

gdal_translate -of GTiff -a_ullr $Q $W $E $R -a_srs 'EPSG:3857' /tmp/au_${3}_${2}.png /tmp/au_${3}_parcels/${2}.tif

rm /tmp/au_${3}_${2}.*
echo "$2/$4"
