# Gleam Zipper

[![Package Version](https://img.shields.io/hexpm/v/gleam_zipper)](https://hex.pm/packages/gleamy_zipper)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleamy_zipper/)
[![Build Status](https://github.com/Frid-Yuandu/zipper/workflows/test/badge.svg)](https://github.com/Frid-Yuandu/zipper/actions)

English | [简体中文 README](./README_zh.md)

A functional zipper library for Gleam. Zippers provide a way to navigate and update immutable data structures in an efficient and elegant way.

This library provides zipper implementations for common data structures like lists, binary trees, and rose trees.

## Philosophy

In functional programming, we work with immutable data. When you need to change an item deep within a complex data structure (like a tree), you would typically have to reconstruct the entire structure.

A **zipper** solves this problem by representing a "focused" position within your data structure, keeping track of the path back to the root. This allows you to treat the data structure as if it were mutable for the purpose of an update, and then efficiently rebuild the structure with the change applied. All operations remain pure and functional.

You can get more details about the zipper data structure from this paper, [*“The Zipper”*](https://www.cambridge.org/core/journals/journal-of-functional-programming/article/zipper/0C058890B8A9B588F26E6D68CF0CE204).

## Core Features

-   **Immutable**: All navigation and modification functions are pure and return a new zipper.
-   **Efficient**: Most local edits and movements are O(1) operations.
-   **Adaptable**: Use the provided standard data types or bring your own! An `Adapter` pattern lets you use the zipper with your custom tree structures.
-   **Ergonomic**: A simple and intuitive API for navigation (`go_up`, `go_down`, `go_left`, `go_right`, etc.) and manipulation.

## Modules

This library provides zippers for:

-   `zipper/list`: For navigating `List`s.
-   `zipper/tree`: For binary trees.
-   `zipper/rose_tree`: For rose trees (multi-way trees).

## Installation

Add `gleam_zipper` to your `gleam.toml` dependencies:

```toml
[dependencies]
gleam_zipper = "~> 0.1.0"
```

## Usage

Here's a quick example of using the zipper with a binary tree:

```gleam
import gleam/io
import zipper/tree

pub fn main() {
  // 1. Define your tree
  let my_tree =
    tree.Node(
      "root",
      tree.Node("left", tree.Leaf, tree.Leaf),
      tree.Node("right", tree.Leaf, tree.Leaf),
    )

  // 2. Create a zipper, focusing on the root
  let zipper = tree.from_standard_tree(my_tree)

  // 3. Navigate and update the tree
  let assert Ok(zipper) = tree.go_left(zipper) // Focus on "left"
  let assert Ok(zipper) = tree.set_value(zipper, "new-left") // Update its value
  let assert Ok(zipper) = tree.go_up(zipper) // Go back to the root

  // 4. Convert the zipper back to a tree
  let updated_tree = tree.to_standard_tree(zipper)

  // The original tree is unchanged, and updated_tree contains the modifications.
  // => Node("root", Node("new-left", Leaf, Leaf), Node("right", Leaf, Leaf))
  echo updated_tree
}
```

## Development

To run the project's tests:

```shell
gleam test
```
