# parcel-au-sa
Scrape CC-BY parcel data for SA, Australia

## Installation

The following dependancies must be met:
- python 2.7
- Standard bash env (any major distro should work)
- curl
- jq
- gdal
- GNU Parallel
- nodejs 0.10.x

## Running

SA, Australia has been split into a series of ~9000 grid cells. Each cell is further broken into ~1500 tiles.
Each image tile is then downloaded and processed into a mosaic for the given grid cell. These grid
cells are then processed to extract a rough outline of the parcels for that cell. The centroid of every
parcel is then used to lookup the details as well as more accurate geometry.

Running the `auto.sh` script will iterate through every grid, scraping the data.
```
./auto.sh
```

To scrape an individual grid you can use the `run.sh` command directly. The grids can be found in `util/grids.geojson`
The grid number refers to the line of the grid file. If you are just testing - grid 8000 will have viable data.
```
./run.sh <grid>
```

