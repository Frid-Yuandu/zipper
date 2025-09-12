//// A functional zipper for rose trees (multi-way trees).
////
//// This module provides tools to navigate and modify rose tree structures
//// efficiently. The zipper makes it easy to move up, down, and sideways
//// in a tree and to perform local modifications without traversing the
//// entire tree.
////
//// Most navigation and local modification operations are $O(1)$. Going up
//// the tree is $O(k)$, where $k$ is the number of left siblings of the
//// current node. Operations that convert from or to a full tree structure
//// are $O(n)$, where $n$ is the number of nodes in the tree.
////
//// It supports both a standard `RoseTree` type and can be adapted to work with
//// any user-defined rose tree structure via an `Adapter`.
////
//// Unlike binary trees, rose trees do not have a separate concept of a leaf node;
//// a node with an empty list of children is considered a leaf. This distinction
//// leads to some differences in the API compared to the `zipper/tree` module.
//// For example, `get_value` always succeeds because every location in a rose
//// tree zipper has a value.
////
//// ## Usage
//// ```gleam
//// import zipper/rose_tree
////
//// let my_tree =
////   rose_tree.RoseTree(1, [
////     rose_tree.RoseTree(2, []),
////     rose_tree.RoseTree(3, []),
////   ])
////
//// let zipper = rose_tree.from_standard_tree(my_tree)
////
//// // Navigate and modify the tree
//// let assert Ok(zipper) = rose_tree.go_down(zipper)
//// let zipper = rose_tree.set_value(zipper, 4)
//// let assert Ok(zipper) = rose_tree.go_up(zipper)
////
//// rose_tree.to_standard_tree(zipper)
//// // => RoseTree(1, [RoseTree(4, []), RoseTree(3, [])])
//// ```

import gleam/list

/// A rose tree (multi-way tree) node data structure.
///
/// - `value` – the payload stored in this node
/// - `children` – list of subtrees (nodes with empty list represent leaves)
pub type RoseTree(a) {
  RoseTree(value: a, children: List(RoseTree(a)))
}

/// Adapter for converting between a user-defined tree type and the standard rose tree type.
///
/// The adapter provides functions to convert between a user-defined tree structure
/// and the standard rose tree representation used by the zipper.
///
/// - `get_value`: Extracts the node value from a user tree node.
/// - `get_children`: Returns a list of standard `RoseTree` children. Note that the
///   implementer of this function is responsible for converting the user-defined
///   child nodes into the standard `RoseTree` format.
/// - `build_node`: Constructs a user tree node from a value and a list of standard
///   `RoseTree` children.
pub type Adapter(a, user_rose_tree) {
  Adapter(
    get_value: fn(user_rose_tree) -> a,
    get_children: fn(user_rose_tree) -> List(RoseTree(a)),
    build_node: fn(a, List(RoseTree(a))) -> user_rose_tree,
  )
}

/// Represents a choice point in the navigation path.
///
/// It stores the context of a parent node, including its value and the siblings
/// surrounding the node from which we descended.
type Choice(a) {
  Choice(
    value: a,
    left_siblings: List(RoseTree(a)),
    right_siblings: List(RoseTree(a)),
  )
}

/// A zipper for navigating and manipulating rose trees.
///
/// Conceptually, a Zipper represents a specific location within a rose tree,
/// effectively partitioning it into the current focused subtree and its surrounding
/// context (the path back to the root, including siblings).
///
/// All functions are pure and do not modify the input Zipper.
/// They return a new Zipper instance representing the modified state.
pub opaque type Zipper(a) {
  Zipper(thread: List(Choice(a)), focus: RoseTree(a))
}

/// Creates a zipper from a standard rose tree.
///
/// The initial focus of the zipper is the root of the tree.
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(1, [])
/// let zipper = from_standard_tree(tree)
/// get_value(zipper)
/// // => 1
/// ```
pub fn from_standard_tree(tree: RoseTree(a)) -> Zipper(a) {
  Zipper(thread: [], focus: tree)
}

/// Converts a zipper back to a standard rose tree.
///
/// This function reconstructs the entire tree by navigating to the root from the
/// current focus and rebuilding the structure along the way.
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(1, [RoseTree(2, [])])
/// let zipper = from_standard_tree(tree)
/// let assert Ok(zipper) = go_down(zipper)
///
/// to_standard_tree(zipper)
/// // => RoseTree(1, [RoseTree(2, [])])
/// ```
pub fn to_standard_tree(zipper: Zipper(a)) -> RoseTree(a) {
  case zipper.thread {
    [] -> zipper.focus
    [Choice(value:, left_siblings:, right_siblings:), ..thread] -> {
      let children =
        list.append(list.reverse(left_siblings), [
          zipper.focus,
          ..right_siblings
        ])
      Zipper(thread:, focus: RoseTree(value:, children:))
      |> to_standard_tree
    }
  }
}

/// Creates a zipper from a user-defined tree using an adapter.
///
/// ## Examples
/// ```gleam
/// // Given a user-defined tree `my_tree` and a corresponding `adapter`:
/// let zipper = from_tree(my_tree, adapter)
///
/// // The zipper can now be navigated and modified.
/// get_value(zipper)
/// // => root_value
/// ```
pub fn from_tree(
  users_tree: user_tree,
  adapter: Adapter(a, user_tree),
) -> Zipper(a) {
  let value = adapter.get_value(users_tree)
  let children = adapter.get_children(users_tree)
  from_standard_tree(RoseTree(value:, children:))
}

/// Converts a zipper back to a user-defined tree using an adapter.
///
/// ## Examples
/// ```gleam
/// // Given a `zipper` and a corresponding `adapter` for a custom tree type:
/// let my_tree = to_tree(zipper, adapter)
///
/// // `my_tree` is now an instance of the custom tree type.
/// ```
pub fn to_tree(zipper: Zipper(a), adapter: Adapter(a, user_tree)) -> user_tree {
  let tree = to_standard_tree(zipper)
  adapter.build_node(tree.value, tree.children)
}

/// Moves the focus to the left sibling of the current node.
///
/// Returns `Ok(zipper)` focused on the left sibling if it exists,
/// or `Error(Nil)` if there is no left sibling (current node is leftmost).
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(1, [RoseTree(2, []), RoseTree(3, [])])
/// let zipper = from_standard_tree(tree)
/// let assert Ok(zipper) = go_down(zipper)
/// let assert Ok(zipper) = go_right(zipper)
/// get_value(zipper)
/// // => 3
///
/// let assert Ok(zipper) = go_left(zipper)
/// get_value(zipper)
/// // => 2
/// ```
pub fn go_left(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case is_leftmost(zipper) {
    True -> Error(Nil)
    False -> {
      let assert [
        Choice(
          value:,
          left_siblings: [new_focus, ..left_siblings],
          right_siblings:,
        ),
        ..rest
      ] = zipper.thread
        as "safe assert"

      let right_siblings = [zipper.focus, ..right_siblings]
      let new_choice = Choice(value:, left_siblings:, right_siblings:)
      Ok(Zipper([new_choice, ..rest], new_focus))
    }
  }
}

/// Moves the focus to the right sibling of the current node.
///
/// Returns `Ok(zipper)` focused on the right sibling if it exists,
/// or `Error(Nil)` if there is no right sibling (current node is rightmost).
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(1, [RoseTree(2, []), RoseTree(3, [])])
/// let zipper = from_standard_tree(tree)
/// let assert Ok(zipper) = go_down(zipper)
/// let assert Ok(zipper) = go_right(zipper)
/// get_value(zipper)
/// // => 3
/// ```
pub fn go_right(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case is_rightmost(zipper) {
    True -> Error(Nil)
    False -> {
      let assert [
        Choice(
          value:,
          left_siblings:,
          right_siblings: [new_focus, ..right_siblings],
        ),
        ..rest
      ] = zipper.thread
        as "safe assert"

      let left_siblings = [zipper.focus, ..left_siblings]
      let new_choice = Choice(value:, left_siblings:, right_siblings:)
      Ok(Zipper([new_choice, ..rest], new_focus))
    }
  }
}

/// Moves the focus to the parent node.
///
/// Returns `Ok(zipper)` focused on the parent node if not at the root.
/// Returns `Error(Nil)` if already at the root.
///
/// This function takes $O(k)$ time,
/// where $k$ is the number of left siblings of the current node.
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(1, [RoseTree(2, [])])
/// let zipper = from_standard_tree(tree)
/// let assert Ok(zipper) = go_down(zipper)
/// get_value(zipper)
/// // => 2
///
/// let assert Ok(zipper) = go_up(zipper)
/// get_value(zipper)
/// // => 1
/// ```
pub fn go_up(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper.thread {
    [] -> Error(Nil)
    [Choice(value, left_siblings, right_siblings), ..rest] -> {
      let children =
        list.append(list.reverse(left_siblings), [
          zipper.focus,
          ..right_siblings
        ])
      let new_focus = RoseTree(value, children)
      Ok(Zipper(rest, new_focus))
    }
  }
}

/// Moves the focus to the first child of the current node.
///
/// Returns `Ok(zipper)` focused on the first child if it exists.
/// Returns `Error(Nil)` if the current node is a leaf (has no children).
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(1, [RoseTree(2, [])])
/// let zipper = from_standard_tree(tree)
///
/// let assert Ok(zipper) = go_down(zipper)
/// get_value(zipper)
/// // => 2
/// ```
pub fn go_down(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper.focus.children {
    [] -> Error(Nil)
    [new_focus, ..new_right_siblings] -> {
      let choice = Choice(zipper.focus.value, [], new_right_siblings)
      Ok(Zipper([choice, ..zipper.thread], new_focus))
    }
  }
}

// TODO: considering add `go_down_at` function to go to the child at a specific index

/// Gets the value of the current focus node.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(RoseTree(42, []))
/// get_value(zipper)
/// // => 42
/// ```
pub fn get_value(zipper: Zipper(a)) -> a {
  zipper.focus.value
}

/// Gets the current focus subtree as a standard rose tree.
///
/// ## Examples
/// ```gleam
/// let child_tree = RoseTree(2, [])
/// let zipper = from_standard_tree(RoseTree(1, [child_tree]))
/// let assert Ok(zipper) = go_down(zipper)
///
/// get_standard_tree(zipper)
/// // => RoseTree(2, [])
/// ```
pub fn get_standard_tree(zipper: Zipper(a)) -> RoseTree(a) {
  zipper.focus
}

/// Gets the current focus subtree as a user-defined tree using an adapter.
///
/// ## Examples
/// ```gleam
/// // Given a `zipper` and a corresponding `adapter` for a custom tree type:
/// let focused_subtree = get_tree(zipper, adapter)
///
/// // `focused_subtree` is an instance of the custom tree type.
/// ```
pub fn get_tree(zipper: Zipper(a), adapter: Adapter(a, user_tree)) -> user_tree {
  let tree = get_standard_tree(zipper)
  adapter.build_node(tree.value, tree.children)
}

/// Sets the value of the current focus node.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(RoseTree(1, []))
/// let zipper = set_value(zipper, 42)
/// get_value(zipper)
/// // => 42
/// ```
pub fn set_value(zipper: Zipper(a), value: a) -> Zipper(a) {
  Zipper(..zipper, focus: RoseTree(..zipper.focus, value:))
}

/// Sets the current focus subtree to a new standard rose tree.
///
/// This replaces the entire focused subtree with the provided tree.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(RoseTree(1, [RoseTree(2, [])]))
/// let new_subtree = RoseTree(99, [])
/// let zipper = set_standard_tree(zipper, new_subtree)
///
/// to_standard_tree(zipper)
/// // => RoseTree(99, [])
/// ```
pub fn set_standard_tree(zipper: Zipper(a), tree: RoseTree(a)) -> Zipper(a) {
  Zipper(..zipper, focus: tree)
}

/// Sets the current focus subtree to a user-defined tree using an adapter.
///
/// ## Examples
/// ```gleam
/// // Given a `zipper`, a `my_subtree` of a user-defined type,
/// // and a corresponding `adapter`:
/// let updated_zipper = set_tree(zipper, my_subtree, adapter)
///
/// // The focus of `updated_zipper` is now `my_subtree`.
/// ```
pub fn set_tree(
  zipper: Zipper(a),
  tree: user_tree,
  adapter: Adapter(a, user_tree),
) -> Zipper(a) {
  let value = adapter.get_value(tree)
  let children = adapter.get_children(tree)
  let new_focus = RoseTree(value, children)
  set_standard_tree(zipper, new_focus)
}

/// Updates the value of the current focus node using a transformation function.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(RoseTree(10, []))
/// let zipper = update(zipper, fn(x) { x * 2 })
/// get_value(zipper)
/// // => 20
/// ```
pub fn update(zipper: Zipper(a), updater: fn(a) -> a) -> Zipper(a) {
  let new_value = updater(get_value(zipper))
  set_value(zipper, new_value)
}

/// Inserts a new tree as the immediate left sibling of the current node.
///
/// Returns `Ok(zipper)` with the new sibling inserted.
/// Returns `Error(Nil)` if the current node is the root.
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(0, [RoseTree(2, [])])
/// let zipper = from_standard_tree(tree) |> go_down // focus on 2
///
/// let new_sibling = RoseTree(1, [])
/// let assert Ok(zipper) = insert_left(zipper, new_sibling)
///
/// to_standard_tree(zipper)
/// // => RoseTree(0, [RoseTree(1, []), RoseTree(2, [])])
/// ```
pub fn insert_left(
  zipper: Zipper(a),
  tree: RoseTree(a),
) -> Result(Zipper(a), Nil) {
  case is_root(zipper) {
    True -> Error(Nil)
    False -> {
      let assert [Choice(left_siblings:, ..) as c, ..rest] = zipper.thread
        as "safe assert"

      let new_left_siblings = [tree, ..left_siblings]
      let new_choice = Choice(..c, left_siblings: new_left_siblings)
      Ok(Zipper(..zipper, thread: [new_choice, ..rest]))
    }
  }
}

/// Inserts a new tree as the immediate right sibling of the current node.
///
/// Returns `Ok(zipper)` with the new sibling inserted.
/// Returns `Error(Nil)` if the current node is the root.
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(0, [RoseTree(1, [])])
/// let zipper = from_standard_tree(tree) |> go_down // focus on 1
///
/// let new_sibling = RoseTree(2, [])
/// let assert Ok(zipper) = insert_right(zipper, new_sibling)
///
/// to_standard_tree(zipper)
/// // => RoseTree(0, [RoseTree(1, []), RoseTree(2, [])])
/// ```
pub fn insert_right(
  zipper: Zipper(a),
  tree: RoseTree(a),
) -> Result(Zipper(a), Nil) {
  case is_root(zipper) {
    True -> Error(Nil)
    False -> {
      let assert [Choice(right_siblings:, ..) as c, ..rest] = zipper.thread
        as "safe assert"

      let new_right_siblings = [tree, ..right_siblings]
      let new_choice = Choice(..c, right_siblings: new_right_siblings)
      Ok(Zipper(..zipper, thread: [new_choice, ..rest]))
    }
  }
}

/// Inserts a new tree as the first child of the current node.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(RoseTree(1, [RoseTree(3, [])]))
/// let zipper = insert_child(zipper, RoseTree(2, []))
///
/// to_standard_tree(zipper)
/// // => RoseTree(1, [RoseTree(2, []), RoseTree(3, [])])
/// ```
pub fn insert_child(zipper: Zipper(a), tree: RoseTree(a)) -> Zipper(a) {
  let RoseTree(value:, children:) = zipper.focus
  let new_children = [tree, ..children]
  let new_focus = RoseTree(value:, children: new_children)
  Zipper(..zipper, focus: new_focus)
}

/// Inserts a new tree as the last child of the current node.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(RoseTree(1, [RoseTree(2, [])]))
/// let zipper = insert_child_back(zipper, RoseTree(3, []))
///
/// to_standard_tree(zipper)
/// // => RoseTree(1, [RoseTree(2, []), RoseTree(3, [])])
/// ```
pub fn insert_child_back(zipper: Zipper(a), tree: RoseTree(a)) -> Zipper(a) {
  let RoseTree(value:, children:) = zipper.focus
  let new_children = list.append(children, [tree])
  let new_focus = RoseTree(value:, children: new_children)
  Zipper(..zipper, focus: new_focus)
}

/// Deletes the current focus node.
///
/// The focus moves to the right sibling if it exists, otherwise to the left
/// sibling, otherwise to the parent.
///
/// Returns `Ok(zipper)` with the focus moved to the new location.
/// Returns `Error(Nil)` if the focus is the root node.
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(0, [RoseTree(1, []), RoseTree(2, []), RoseTree(3, [])])
/// let zipper = from_standard_tree(tree)
/// let assert Ok(zipper) = go_down(zipper) // focus on 1
/// let assert Ok(zipper) = go_right(zipper) // focus on 2
///
/// let assert Ok(zipper) = delete(zipper)
/// get_value(zipper) // focus moved to the right sibling
/// // => 3
///
/// to_standard_tree(zipper)
/// // => RoseTree(0, [RoseTree(1, []), RoseTree(3, [])])
/// ```
pub fn delete(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper.thread {
    [] -> Error(Nil)
    [Choice(value, left_siblings, right_siblings), ..rest] ->
      case right_siblings {
        [new_focus, ..rs] -> {
          let new_choice = Choice(value, left_siblings, rs)
          Ok(Zipper([new_choice, ..rest], new_focus))
        }
        [] ->
          case left_siblings {
            [new_focus, ..ls] -> {
              let new_choice = Choice(value, ls, [])
              Ok(Zipper([new_choice, ..rest], new_focus))
            }
            [] -> {
              let new_focus = RoseTree(value, [])
              Ok(Zipper(rest, new_focus))
            }
          }
      }
  }
}

/// Checks if the current focus is the root of the tree.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(RoseTree(1, [RoseTree(2, [])]))
/// is_root(zipper)
/// // => True
///
/// let assert Ok(child_zipper) = go_down(zipper)
/// is_root(child_zipper)
/// // => False
/// ```
pub fn is_root(zipper: Zipper(a)) -> Bool {
  case zipper.thread {
    [] -> True
    _ -> False
  }
}

/// Checks if the current focus node is a leaf (has no children).
///
/// ## Examples
/// ```gleam
/// let leaf_zipper = from_standard_tree(RoseTree(1, []))
/// is_leaf(leaf_zipper)
/// // => True
///
/// let node_zipper = from_standard_tree(RoseTree(1, [RoseTree(2, [])]))
/// is_leaf(node_zipper)
/// // => False
/// ```
pub fn is_leaf(zipper: Zipper(a)) -> Bool {
  case zipper.focus.children {
    [] -> True
    _ -> False
  }
}

/// Checks if the current focus node is the leftmost among its siblings.
///
/// Returns `True` if the node is the root or has no left siblings.
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(0, [RoseTree(1, []), RoseTree(2, [])])
/// let zipper = from_standard_tree(tree)
/// let assert Ok(zipper) = go_down(zipper) // focus on 1
///
/// is_leftmost(zipper)
/// // => True
/// ```
pub fn is_leftmost(zipper: Zipper(a)) -> Bool {
  case zipper.thread {
    [] -> True
    [Choice(left_siblings: [], ..), ..] -> True
    _ -> False
  }
}

/// Checks if the current focus node is the rightmost among its siblings.
///
/// Returns `True` if the node is the root or has no right siblings.
///
/// ## Examples
/// ```gleam
/// let tree = RoseTree(0, [RoseTree(1, []), RoseTree(2, [])])
/// let zipper = from_standard_tree(tree)
/// let assert Ok(zipper) = go_down(zipper)
/// let assert Ok(zipper) = go_right(zipper) // focus on 2
///
/// is_rightmost(zipper)
/// // => True
/// ```
pub fn is_rightmost(zipper: Zipper(a)) -> Bool {
  case zipper.thread {
    [] -> True
    [Choice(right_siblings: [], ..), ..] -> True
    _ -> False
  }
}
