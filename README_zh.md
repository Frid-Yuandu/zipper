# Gleam Zipper

[![Package Version](https://img.shields.io/hexpm/v/gleam_zipper)](https://hex.pm/packages/gleamy_zipper)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleamy_zipper/)
[![Build Status](https://github.com/Frid-Yuandu/zipper/workflows/test/badge.svg)](https://github.com/Frid-Yuandu/zipper/actions)

[English README](./README.md) | 简体中文

一个为 Gleam 语言设计的功能性 zipper 库。Zipper 提供了一种高效且优雅的方式来导航和更新不可变数据结构。

本库为常见数据结构（如列表、二叉树和玫瑰树）提供了 zipper 实现。

## 设计理念

在函数式编程中，我们使用不可变数据。当需要修改复杂数据结构深处的某个项目时，通常需要重建整个结构。

**Zipper** 通过在数据结构中表示一个"焦点"位置，并追踪回到根节点的路径来解决这个问题。这允许你将数据结构当作可变的来进行更新，然后高效地应用更改并重建结构。所有操作都保持纯粹和函数式特性。

你可以从这篇论文 [*"The Zipper"*](https://www.cambridge.org/core/journals/journal-of-functional-programming/article/zipper/0C058890B8A9B588F26E6D68CF0CE204) 中获取关于 zipper 数据结构的更多细节。

## 核心特性

-   **不可变性**：所有导航和修改函数都是纯函数，返回新的 zipper。
-   **高效性**：大多数本地编辑和移动操作都是 O(1) 时间复杂度。
-   **可适配性**：使用提供的标准数据类型，或者使用你自己的数据类型！`Adapter` 模式让你可以将 zipper 与自定义树结构一起使用。
-   **易用性**：为导航（`go_up`、`go_down`、`go_left`、`go_right` 等）和操作提供简单直观的 API。

## 模块

本库为以下数据结构提供 zipper：

-   `zipper/list`：用于导航 `List` 列表。
-   `zipper/tree`：用于二叉树。
-   `zipper/rose_tree`：用于玫瑰树（多叉树）。

## 安装

将 `gleam_zipper` 添加到你的 `gleam.toml` 依赖中：

```toml
[dependencies]
gleam_zipper = "~> 0.1.0"
```

## 使用方法

以下是使用二叉树 zipper 的快速示例：

```gleam
import gleam/io
import zipper/tree

pub fn main() {
  // 1. 定义你的树
  let my_tree =
    tree.Node(
      "root",
      tree.Node("left", tree.Leaf, tree.Leaf),
      tree.Node("right", tree.Leaf, tree.Leaf),
    )

  // 2. 创建 zipper，聚焦在根节点
  let zipper = tree.from_standard_tree(my_tree)

  // 3. 导航并更新树
  let assert Ok(zipper) = tree.go_left(zipper) // 聚焦到 "left"
  let assert Ok(zipper) = tree.set_value(zipper, "new-left") // 更新其值
  let assert Ok(zipper) = tree.go_up(zipper) // 回到根节点

  // 4. 将 zipper 转换回树
  let updated_tree = tree.to_standard_tree(zipper)

  // 原始树保持不变，updated_tree 包含修改。
  // => Node("root", Node("new-left", Leaf, Leaf), Node("right", Leaf, Leaf))
  echo updated_tree
}
```

## 开发

要运行项目的测试：

```shell
gleam test
```