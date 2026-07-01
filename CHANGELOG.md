# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Adapter API — internal types no longer leak into user callbacks / Adapter API — 内部类型不再泄漏到用户回调中**

  - `zipper/tree`: `build_node` signature changed from `fn(Option(a), #(Option(Tree(a)), Option(Tree(a)))) -> user_tree` to `fn(Option(a), #(Option(user_tree), Option(user_tree))) -> user_tree`. The library now performs recursive conversion internally.

  - `zipper/tree`: `build_node` 签名从 `fn(Option(a), #(Option(Tree(a)), Option(Tree(a)))) -> user_tree` 改为 `fn(Option(a), #(Option(user_tree), Option(user_tree))) -> user_tree`。库现在内部进行递归转换。

  - `zipper/rose_tree`: `get_children` changed from `fn(user_rose_tree) -> List(RoseTree(a))` to `fn(user_rose_tree) -> List(user_rose_tree)`, and `build_node` changed from `fn(a, List(RoseTree(a))) -> user_rose_tree` to `fn(a, List(user_rose_tree)) -> user_rose_tree`. The library now performs recursive conversion internally via `user_tree_to_standard_tree` and `standard_tree_to_user_tree`.

  - `zipper/rose_tree`: `get_children` 从 `fn(user_rose_tree) -> List(RoseTree(a))` 改为 `fn(user_rose_tree) -> List(user_rose_tree)`，`build_node` 从 `fn(a, List(RoseTree(a))) -> user_rose_tree` 改为 `fn(a, List(user_rose_tree)) -> user_rose_tree`。库现在通过 `user_tree_to_standard_tree` 和 `standard_tree_to_user_tree` 内部进行递归转换。

  - Users no longer need to import or handle internal `Tree(a)` / `RoseTree(a)` types in adapter callbacks. / 用户不再需要在 adapter 回调中导入或处理内部 `Tree(a)` / `RoseTree(a)` 类型。

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
