for GRID in $(seq $(wc -l util/grids.geojson | grep -Eo '[0-9]+') -1 1); do
    if [ ! -f out/au_${GRID}.geojson ]; then
        ./run.sh $GRID
    else
        echo "# Grid ($GRID) already processed"
    fi
done
