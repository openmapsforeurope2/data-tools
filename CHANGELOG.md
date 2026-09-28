## [1.1.0] - 2026-09-28
### Added
- Added the `prepare_data` utility, including data validation.
- Added support for preparing administrative unit matching data at all administrative levels.
- Added support for validation of neighbouring countries in `prepare_data`.
- Added a `release` schema with functions to create views for data release.
- Added functions to update country codes.
- Added functions to correct duplicate attribute values on edge-matched objects.
- Added support for tables without geometry when creating triggers.
- Added support for tables with multiple geometry columns.
- Added the `sql_run` utility.
- Added database name parameters to relevant scripts.
- Added `extract` and `border_extract` functions.

### Changed
- Reorganised the project and separated functionality between the `ome2-data` and `data-tools` repositories.
- Updated the data model configuration following changes to the OME2 data model.
- Updated preparation and validation processes for network matching and administrative unit matching.
- Updated the handling of destroyed objects.
- Removed country codes from generated table suffixes.
- Updated the `border_extract` interface and parameters.
- Updated extraction distances for hydrographic data for Switzerland and Liechtenstein.
- Updated landmask generation to use administrative unit areas.
- Updated database creation and initialization scripts.
- Updated Docker configuration and adapted the application to the IGN-MUT environment.
- Updated scripts and documentation to support the new production workflow.

### Fixed
- Fixed handling of deleted boundaries in border extraction.
- Fixed cleaning of working tables and improved working table name handling.
- Fixed filtering of destroyed objects during cleaning operations.
- Fixed handling of special characters in JSON/JSONB fields.
- Fixed country and neighbour data used during processing.
- Fixed various SQL queries and database initialization issues.
- Fixed command-line argument checking and improved error messages.
- Fixed issues related to database schemas, functions and trigger creation.
- Fixed attribute and table handling following OME2 data model changes.


## [1.0.0] - 2025-03-24
### Added
- Initial release of the project

### Changed
- NTR

### Fixed
- NTR