for GRID in $(seq 1 $(wc -l util/grids.geojson | grep -Eo '[0-9]+')); do
    ./run.sh $GRID
done
