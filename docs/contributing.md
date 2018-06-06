---
layout: legacy
---

# Contributing

## Incrementing versions

- Update /Koha/Plugin/EDS/admin/release_notes.xml

- Update /Koha/Plugin/EDS.pm
    - Change master version $MAJOR_VERSION variable (if required)
    - Increment sub version $SUB_VERSION variable

- Add version and commit hash to legacy JSON
    - [./legacy/1711.json](./legacy/1711.json)

- Update /Koha/Plugin/EDS/js/EDSScript.js
    - Change variable versionEDSKoha;

- Update the build.sh kpz
    - eds_plugin_XX.XXXX.kpz

## Packing the KPZ

Run build.sh