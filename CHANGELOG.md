# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-09-17

### Fixed

- **List Zipper Navigation**: Fixed bug in `go_right` function where it would incorrectly handle navigation when at the rightmost element
- **Delete Operation**: Fixed bug where deleting the only element in a zipper would lead to invalid state
- **Boundary Conditions**: Improved handling of edge cases in list zipper operations

### Changed

- Simplified pattern matching in `is_leftmost` and `is_rightmost` functions
- Simplified pattern matching in `insert_left` function

## [0.1.0] - 2025-09-10

### Added

- Initial release of gleamy_zipper
- List zipper implementation with navigation and manipulation functions
- Binary tree zipper implementation
- Rose tree zipper implementation
- Comprehensive test suite with property-based tests