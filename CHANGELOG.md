# Changelog / 更新日志

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

本项目所有值得注意的变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [0.2.0] - 2026-07-01

### Added

- **Rose Tree `map_focus`**: Added `map_focus` function to `zipper/rose_tree`, allowing transformation of the entire `RoseTree(a)` at focus (value and children) via a callback. Includes property-based tests covering identity, composition, focus equivalence, navigation preservation, and round-trip invariants.
- **`go_to_root` Documentation and Tests**: Added detailed documentation with usage examples for `go_to_root` in both `zipper/tree` and `zipper/rose_tree`. Added doctests and property-based tests covering root focus, non-root focus, idempotence, structural preservation, and agreement with repeated `go_up`.
- **Shared Test Generators**: Extracted the `fixpoint` helper into `test/helpers/generators.gleam` and added arbitrary-position zipper generators for binary trees and rose trees to support property-based testing.

### 新增

- **玫瑰树 `map_focus`**: 为 `zipper/rose_tree` 新增 `map_focus` 函数，允许通过回调变换焦点的整棵 `RoseTree(a)`（值及子节点）。包含基于属性的测试，覆盖恒等性、组合性、焦点等价性、导航不变性和往返等价性。
- **`go_to_root` 文档与测试**: 为 `zipper/tree` 和 `zipper/rose_tree` 中的 `go_to_root` 添加详细文档与使用示例。新增文档测试和基于属性的测试，覆盖根节点焦点、非根节点焦点、幂等性、结构保持以及与重复调用 `go_up` 的等价性。
- **共享测试生成器**: 将 `fixpoint` 辅助函数提取到 `test/helpers/generators.gleam`，并为二叉树和玫瑰树新增任意位置 zipper 生成器，以支持基于属性的测试。

### Changed

- **Adapter API — internal types no longer leak into user callbacks / Adapter API — 内部类型不再泄漏到用户回调中**

  - `zipper/tree`: `build_node` signature changed from `fn(Option(a), #(Option(Tree(a)), Option(Tree(a)))) -> user_tree` to `fn(Option(a), #(Option(user_tree), Option(user_tree))) -> user_tree`. The library now performs recursive conversion internally.

  - `zipper/tree`: `build_node` 签名从 `fn(Option(a), #(Option(Tree(a)), Option(Tree(a)))) -> user_tree` 改为 `fn(Option(a), #(Option(user_tree), Option(user_tree))) -> user_tree`。库现在内部进行递归转换。

  - `zipper/rose_tree`: `get_children` changed from `fn(user_rose_tree) -> List(RoseTree(a))` to `fn(user_rose_tree) -> List(user_rose_tree)`, and `build_node` changed from `fn(a, List(RoseTree(a))) -> user_rose_tree` to `fn(a, List(user_rose_tree)) -> user_rose_tree`. The library now performs recursive conversion internally via `user_tree_to_standard_tree` and `standard_tree_to_user_tree`.

  - `zipper/rose_tree`: `get_children` 从 `fn(user_rose_tree) -> List(RoseTree(a))` 改为 `fn(user_rose_tree) -> List(user_rose_tree)`，`build_node` 从 `fn(a, List(RoseTree(a))) -> user_rose_tree` 改为 `fn(a, List(user_rose_tree)) -> user_rose_tree`。库现在通过 `user_tree_to_standard_tree` 和 `standard_tree_to_user_tree` 内部进行递归转换。

  - Users no longer need to import or handle internal `Tree(a)` / `RoseTree(a)` types in adapter callbacks. / 用户不再需要在 adapter 回调中导入或处理内部 `Tree(a)` / `RoseTree(a)` 类型。

- **List Zipper Examples**: Comprehensively optimized documentation examples — variable names changed from single-letter to semantic (`z` → `zipper`), pipe chains replaced with step-by-step `let` bindings for clarity.
- **List Zipper Behavior Notes**: Added behavior clarification for `insert_right` when the zipper is empty.
- **Rose Tree Complexity**: Added time complexity documentation for `insert_child_back` ($O(d)$) and module-level complexity notes.
- **Doctest Coverage**: Added 6 previously missing doctest functions in `test/list_test.gleam` (`new`, `from_list`, `to_list`, `get`, `insert_left`, `insert_right`), bringing doctest coverage to 100%.

### 变更

- **Adapter API — 内部类型不再泄漏到用户回调中**

  - `zipper/tree`: `build_node` 签名从 `fn(Option(a), #(Option(Tree(a)), Option(Tree(a)))) -> user_tree` 改为 `fn(Option(a), #(Option(user_tree), Option(user_tree))) -> user_tree`。库现在内部进行递归转换。

  - `zipper/rose_tree`: `get_children` 从 `fn(user_rose_tree) -> List(RoseTree(a))` 改为 `fn(user_rose_tree) -> List(user_rose_tree)`，`build_node` 从 `fn(a, List(RoseTree(a))) -> user_rose_tree` 改为 `fn(a, List(user_rose_tree)) -> user_rose_tree`。库现在通过 `user_tree_to_standard_tree` 和 `standard_tree_to_user_tree` 内部进行递归转换。

  - 用户不再需要在 adapter 回调中导入或处理内部 `Tree(a)` / `RoseTree(a)` 类型。

- **列表 Zipper 示例**: 全面优化了文档示例——变量名从单字母改为语义化命名（`z` → `zipper`），管道链替换为逐步 `let` 绑定以提高可读性。
- **列表 Zipper 行为说明**: 补充了 `insert_right` 在 zipper 为空时的行为说明。
- **玫瑰树复杂度**: 补充了 `insert_child_back` 的时间复杂度文档（$O(d)$）及模块级别的复杂度说明。
- **文档测试覆盖率**: 新增了 `test/list_test.gleam` 中 6 个之前缺失的文档测试函数（`new`、`from_list`、`to_list`、`get`、`insert_left`、`insert_right`），文档测试覆盖率达到 100%。

### Deprecated

- **`get` and `set`**: Deprecated `get` and `set` functions in `zipper/list` in favor of more explicitly named `get_value` and `set_value`. The old functions remain available but are marked with `@deprecated` annotations. All internal tests and documentation have been updated to use the new functions.

### 弃用

- **`get` 和 `set`**: 弃用了 `zipper/list` 中的 `get` 和 `set` 函数，改为使用命名更明确的 `get_value` 和 `set_value`。旧函数仍然可用，但已标记 `@deprecated` 注解。所有内部测试和文档已更新为使用新函数。

### Fixed

- **List Zipper Doc Example**: Fixed `update` doc example that incorrectly showed `// => Ok([2, 2, 3])` instead of `// => [2, 2, 3]` (`to_list` returns `List`, not `Result`).
- **Rose Tree Doc Examples**: Fixed `insert_left` and `insert_right` doc examples where `Result` type from `go_down` was not properly unwrapped.
- **Binary Tree Doc Examples**: Fixed `delete`, `is_root`, and `go_up` doc examples missing `assert` in pattern matching of `Result`.

### 修复

- **列表 Zipper 文档示例**: 修复了 `update` 文档示例中错误地显示 `// => Ok([2, 2, 3])` 而非 `// => [2, 2, 3]` 的问题（`to_list` 返回 `List`，不是 `Result`）。
- **玫瑰树文档示例**: 修复了 `insert_left` 和 `insert_right` 文档示例中 `go_down` 返回的 `Result` 类型未正确解包的问题。
- **二叉树文档示例**: 修复了 `delete`、`is_root` 和 `go_up` 文档示例中对 `Result` 进行模式匹配时缺少 `assert` 的问题。

## [0.1.1] - 2025-09-17

### Fixed

- **List Zipper Navigation**: Fixed bug in `go_right` function where it would incorrectly handle navigation when at the rightmost element.
- **Delete Operation**: Fixed bug where deleting the only element in a zipper would lead to invalid state.
- **Boundary Conditions**: Improved handling of edge cases in list zipper operations.

### 修复

- **列表 Zipper 导航**: 修复了 `go_right` 函数在到达最右侧元素时错误处理导航的 bug。
- **删除操作**: 修复了删除 zipper 中唯一元素会导致无效状态的 bug。
- **边界条件**: 改进了列表 zipper 操作中边界情况的处理。

## [0.1.0] - 2025-09-10

### Added

- Initial release of gleamy_zipper.
- List zipper implementation with navigation and manipulation functions.
- Binary tree zipper implementation.
- Rose tree zipper implementation.
- Comprehensive test suite with property-based tests.

### 新增

- gleamy_zipper 初始发布。
- 列表 zipper 实现，包含导航和操作函数。
- 二叉树 zipper 实现。
- 玫瑰树 zipper 实现。
- 完整的测试套件，包含基于属性的测试。
