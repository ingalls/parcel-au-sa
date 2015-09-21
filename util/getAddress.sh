# Args
# $1 COORDS 
# $2 Job #
# $3 Total Jobs
# $4 Grid

function getLatLng() {
    QUERY=$(echo \
        "http://maps.sa.gov.au/arcgis/rest/services/DPTIExtLandServices/PropertyLocationBrowser20/MapServer/identify" \
        "?f=json" \
        "&geometry=%7B%22x%22%3A${1}%2C%22y%22%3A${2}%2C%22spatialReference%22%3A%7B%22wkid%22%3A4326%7D%7D" \
        '&tolerance=3' \
        '&returnGeometry=true' \
        '&mapExtent=%7B%22xmin%22%3A15385263.732790709%2C%22ymin%22%3A-3942390.4220425757%2C%22xmax%22%3A15386210.23818015%2C%22ymax%22%3A-3942155.1393148527%2C%22spatialReference%22%3A%7B%22wkid%22%3A3857%7D%7D' \
        '&imageDisplay=1459%2C777%2C96' \
        '&geometryType=esriGeometryPoint' \
        '&sr=4326' \
        '&layers=all%3A35' \
        | sed 's/ //g'
    )

    curl -s \
        -H 'Host: maps.sa.gov.au' \
        -H 'Referer: http://maps.sa.gov.au/plb/' \
        "$QUERY"
}

COORD=$(echo $1 | sed 's/\\//g')
ADDR=$(getLatLng $(echo $COORD | jq '.[0]') $(echo $COORD | jq '.[1]'))

echo "{" \
     "  \"type\": \"Feature\"," \
     "  \"properties\": {" \
     "    \"number\": \"$(echo $ADDR | jq -r -c '.results[0].attributes["Street No"]')\"," \
     "    \"street\": \"$(echo $ADDR | jq -r -c '.results[0].attributes["Street Name"]') $(echo $ADDR | jq -r -c '.results[0].attributes["Street Type"]')\"," \
     "    \"suburb\": \"$(echo $ADDR | jq -r -c '.results[0].attributes["Suburb"]')\"," \
     "    \"hundred\": \"$(echo $ADDR | jq -r -c '.results[0].attributes["Hundred"]')\"," \
     "    \"pid\": \"$(echo $ADDR | jq -r -c '.results[0].attributes["PARCEL_IDENTIFIER"]')\"" \
     "  }," \
     "  \"geometry\": {" \
     "    \"type\": \"Polygon\"," \
     "    \"coordinates\": $(echo $ADDR | jq -r -c '.results[0].geometry.rings')" \
     "   }" \
     "}," >> au_${4}.geojson

echo "$2/$3"
