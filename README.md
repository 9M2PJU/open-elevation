# Open-Elevation

[https://open-elevation.com](https://open-elevation.com)

A free and open-source elevation API.

**Open-Elevation** is a free and open-source alternative to the [Google Elevation API](https://developers.google.com/maps/documentation/elevation/start) and similar offerings.

This service came out of the need to have a hosted, easy to use and easy to setup elevation API. While there are some alternatives out there, none of them work out of the box, and seem to point to dead datasets. <b>Open-Elevation</b> is [easy to setup](https://github.com/Jorl17/open-elevation/blob/master/docs/host-your-own.md), has its own docker image and provides scripts for you to easily acquire whatever datasets you want. We offer you the whole world with our [public API](https://github.com/Jorl17/open-elevation/blob/master/docs/api.md).

If you enjoy our service, please consider [donating to us](https://open-elevation.com#donate). Servers aren't free :)

**API Docs are [available here](https://github.com/Jorl17/open-elevation/blob/master/docs/api.md)**

You can learn more about the project, including its **free public API** in [the website](https://open-elevation.com)

## Donations

Please consider donating to keep the public API alive. This API is **used by millions of users every day** and it costs money to keep running!

You can donate [by following this link](https://www.open-elevation.com/#donate).

## Docker Compose Dataset Modes

`docker-compose.yml` exposes dataset switches under `services.server.environment`.

By default, Open-Elevation downloads and builds the whole-world SRTM dataset when `./data` has no `.tif` files:

```yaml
OPEN_ELEVATION_AUTO_DOWNLOAD_DATA: "true"
OPEN_ELEVATION_PARALLEL_DOWNLOADS: "true"
OPEN_ELEVATION_DOWNLOAD_STATUS_INTERVAL: "15"
OPEN_ELEVATION_AUTO_BUILD_REGION: "false"
```

To build only a specific latitude/longitude region, place source GeoTIFF files in `./source-data`, then enable regional mode and fill all four bounds:

```yaml
OPEN_ELEVATION_AUTO_DOWNLOAD_DATA: "true"
OPEN_ELEVATION_AUTO_BUILD_REGION: "true"
OPEN_ELEVATION_REGION_MIN_LATITUDE: "1.0"
OPEN_ELEVATION_REGION_MAX_LATITUDE: "2.0"
OPEN_ELEVATION_REGION_MIN_LONGITUDE: "103.0"
OPEN_ELEVATION_REGION_MAX_LONGITUDE: "104.0"
```

Regional mode runs before whole-world mode. It clips the mounted source GeoTIFFs into `./data` and tiles only that area. It does not download regional source data by itself; your source files must already cover the requested bounding box.

When `docker compose up --build` needs to build a dataset, the logs show clear phases:

* active dataset mode: whole world, regional, or existing data
* parallel SRTM archive downloads with resume status and periodic size/status updates
* archive extraction progress
* extracted raster preparation
* per-raster tiling progress with tile count and percentage
* cleanup and final tile count

Set `OPEN_ELEVATION_PARALLEL_DOWNLOADS` to `"false"` if you prefer one archive download at a time. Increase or decrease `OPEN_ELEVATION_DOWNLOAD_STATUS_INTERVAL` to change how often the Compose logs print the download status table.
