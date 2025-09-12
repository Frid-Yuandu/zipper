//// A functional zipper data structure for binary trees.
////
//// This module provides tools to navigate and modify binary tree structures
//// efficiently. The zipper makes it easy to move up, down, and sideways
//// in a tree and to perform local modifications without traversing the
//// entire tree.
////
//// Most navigation and local modification operations are $O(1)$. Operations
//// that convert from or to a full tree structure are $O(n)$, where $n$ is the
//// number of nodes in the tree. Reconstructing the tree by navigating to the
//// root is $O(d)$, where $d$ is the depth of the current focus.
////
//// It supports both a standard `Tree` type and can be adapted to work with
//// any user-defined binary tree structure via an `Adapter`.
////
//// ## Usage
//// ```gleam
//// import zipper/tree
////
//// let my_tree =
////   tree.Node(1, tree.Node(2, tree.Leaf, tree.Leaf), tree.Node(3, tree.Leaf, tree.Leaf))
////
//// let zipper = tree.from_standard_tree(my_tree)
////
//// // Navigate and modify the tree
//// let assert Ok(zipper) = tree.go_left(zipper)
//// let assert Ok(zipper) = tree.set_value(zipper, 4)
//// let assert Ok(zipper) = tree.go_up(zipper)
////
//// tree.to_standard_tree(zipper)
//// // => Node(1, Node(4, Leaf, Leaf), Node(3, Leaf, Leaf))
//// ```

import gleam/option.{type Option, None, Some}

// pub type TraverseOrder {
//   PreOrder
//   InOrder
//   PostOrder
// }

/// A binary tree data structure.
///
/// - `Leaf`: Represents an empty tree or terminal node
/// - `Node(value, left, right)`: Represents a node with a value and two subtrees
pub type Tree(a) {
  Leaf
  Node(value: a, left: Tree(a), right: Tree(a))
}

/// Adapter for converting between a user-defined tree type and the standard tree type.
///
/// The adapter provides functions to convert between a user-defined tree structure
/// and the standard binary tree representation used by the zipper.
///
// - `get_value`: Extracts the node value from a user tree node. Returns `None` for

///   leaf nodes, which correspond to the standard tree's `Leaf` constructor.
/// - `get_children`: Returns a tuple `#(left, right)` where `left` and `right` are
///   optional user tree nodes representing the left and right subtrees respectively.
/// - `build_node`: Constructs a user tree node from an optional value and a tuple
///   of optional standard tree subtrees. A `None` value corresponds to a leaf node.
///
/// The mapping between user tree nodes and standard tree nodes is:
/// - User tree node with `None` value ↔ Standard tree `Leaf`
/// - User tree node with `Some(value)` ↔ Standard tree `Node(value, left, right)`
/// - The tuple `#(left, right)` in both directions represents left and right subtrees
pub type Adapter(a, user_tree) {
  Adapter(
    get_value: fn(user_tree) -> Option(a),
    get_children: fn(user_tree) -> #(Option(user_tree), Option(user_tree)),
    build_node: fn(Option(a), #(Option(Tree(a)), Option(Tree(a)))) -> user_tree,
  )
}

/// A zipper for navigating and manipulating binary trees.
///
/// Conceptually, a Zipper represents a specific location within a tree,
/// effectively partitioning it into the current focused subtree and its surrounding
/// context (the path back to the root).
///
/// All functions are pure and do not modify the input Zipper.
/// They return a new Zipper instance representing the modified state.
///
/// This structure allows for efficient navigation and modification of the tree.
pub opaque type Zipper(a) {
  Zipper(thread: List(Choice(a)), focus: Tree(a))
}

/// Represents a choice point in the navigation path.
///
/// - `Left(value, sibling)`: Came from left child, with parent value and right sibling
/// - `Right(value, sibling)`: Came from right child, with parent value and left sibling
type Choice(a) {
  Left(value: a, sibling: Tree(a))
  Right(value: a, sibling: Tree(a))
}

/// Creates a zipper from a standard binary tree.
///
/// ## Examples
/// ```gleam
/// let tree = Node(1, Leaf, Leaf)
/// let zipper = from_standard_tree(tree)
/// ```
pub fn from_standard_tree(tree: Tree(a)) -> Zipper(a) {
  Zipper(thread: [], focus: tree)
}

/// Converts a zipper back to a standard binary tree.
///
/// This function reconstructs the original tree by walking back up
/// the navigation path and rebuilding the tree structure.
///
/// ## Examples
/// ```gleam
/// let tree = Node(1, Leaf, Leaf)
/// let zipper = from_standard_tree(tree)
/// to_standard_tree(zipper)
/// // => Node(1, Leaf, Leaf)
/// ```
pub fn to_standard_tree(zipper: Zipper(a)) -> Tree(a) {
  case zipper {
    Zipper(thread: [], focus:) -> focus
    Zipper(thread: [Left(value:, sibling:), ..thread], focus:) ->
      to_standard_tree(Zipper(
        thread:,
        focus: Node(value:, left: focus, right: sibling),
      ))
    Zipper(thread: [Right(value:, sibling:), ..thread], focus:) ->
      to_standard_tree(Zipper(
        thread:,
        focus: Node(value:, left: sibling, right: focus),
      ))
  }
}

/// Converts a user-defined tree to a standard binary tree using an adapter.
///
/// This internal function recursively converts a user tree structure to the
/// standard tree representation used by the zipper.
fn user_tree_to_standard_tree(
  users_tree: user_tree,
  adapter: Adapter(a, user_tree),
) -> Tree(a) {
  let value = adapter.get_value(users_tree)
  let children = adapter.get_children(users_tree)
  case value, children {
    None, _ -> Leaf
    Some(value), #(None, None) -> Node(value:, left: Leaf, right: Leaf)
    Some(value), #(Some(left), None) ->
      Node(value:, left: user_tree_to_standard_tree(left, adapter), right: Leaf)
    Some(value), #(None, Some(right)) ->
      Node(
        value:,
        left: Leaf,
        right: user_tree_to_standard_tree(right, adapter),
      )
    Some(value), #(Some(left), Some(right)) ->
      Node(
        value:,
        left: user_tree_to_standard_tree(left, adapter),
        right: user_tree_to_standard_tree(right, adapter),
      )
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
/// // => Ok(root_value)
/// ```
pub fn from_tree(
  users_tree: user_tree,
  adapter: Adapter(a, user_tree),
) -> Zipper(a) {
  user_tree_to_standard_tree(users_tree, adapter)
  |> from_standard_tree
}

/// Converts a standard binary tree to a user-defined tree using an adapter.
///
/// This internal function converts the standard tree representation back to
/// the user's tree structure using the provided adapter.
fn standard_tree_to_user_tree(
  tree: Tree(a),
  adapter: Adapter(a, user_tree),
) -> user_tree {
  let #(value, children) = case tree {
    Leaf -> #(None, #(None, None))
    Node(value:, left: Leaf, right: Leaf) -> #(Some(value), #(None, None))
    Node(value:, left:, right: Leaf) -> #(Some(value), #(Some(left), None))
    Node(value:, left: Leaf, right:) -> #(Some(value), #(None, Some(right)))
    Node(value:, left:, right:) -> #(Some(value), #(Some(left), Some(right)))
  }
  adapter.build_node(value, children)
}

/// Converts a zipper to a user-defined tree using an adapter.
///
/// ## Examples
/// ```gleam
/// // Given a `zipper` and a corresponding `adapter` for a custom tree type:
/// let my_tree = to_tree(zipper, adapter)
///
/// // `my_tree` is now an instance of the custom tree type.
/// ```
pub fn to_tree(zipper: Zipper(a), adapter: Adapter(a, user_tree)) -> user_tree {
  to_standard_tree(zipper)
  |> standard_tree_to_user_tree(adapter)
}

/// Gets the value of the current focus node.
///
/// Returns `Ok(value)` if the focus is a node with a value,
/// or `Error(Nil)` if the focus is a leaf node.
///
/// ## Examples
/// ```gleam
/// let node_zipper = from_standard_tree(Node(42, Leaf, Leaf))
/// get_value(node_zipper)
/// // => Ok(42)
///
/// let leaf_zipper = from_standard_tree(Leaf)
/// get_value(leaf_zipper)
/// // => Error(Nil)
/// ```
pub fn get_value(zipper: Zipper(a)) -> Result(a, Nil) {
  case zipper {
    Zipper(_, focus: Leaf) -> Error(Nil)
    Zipper(_, focus: Node(value:, ..)) -> Ok(value)
  }
}

/// Gets the current focus subtree as a standard tree.
///
/// ## Examples
/// ```gleam
/// let tree = Node(1, Leaf, Leaf)
/// let zipper = from_standard_tree(tree)
/// get_standard_tree(zipper)
/// // => Node(1, Leaf, Leaf)
/// ```
pub fn get_standard_tree(zipper: Zipper(a)) -> Tree(a) {
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
  get_standard_tree(zipper)
  |> standard_tree_to_user_tree(adapter)
}

/// Sets the value of the current focus node.
///
/// Returns `Ok(zipper)` with the updated value if the focus is a node,
/// or `Error(Nil)` if the focus is a leaf node.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Leaf, Leaf))
/// case set_value(zipper, 42) {
///   Ok(zipper) -> get_value(zipper)
///   _ -> Error(Nil)
/// }
/// // => Ok(42)
/// ```
pub fn set_value(zipper: Zipper(a), value: a) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: Leaf) -> Error(Nil)
    Zipper(_, focus: Node(value: _, ..) as focus) ->
      Ok(Zipper(..zipper, focus: Node(..focus, value:)))
  }
}

/// Sets the current focus subtree to a new standard tree.
///
/// This replaces the entire focused subtree with the provided tree.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Leaf, Leaf))
/// let new_tree = Node(2, Leaf, Leaf)
/// let updated_zipper = set_standard_tree(zipper, new_tree)
///
/// get_standard_tree(updated_zipper)
/// // => Node(2, Leaf, Leaf)
/// ```
pub fn set_standard_tree(zipper: Zipper(a), tree: Tree(a)) -> Zipper(a) {
  Zipper(..zipper, focus: tree)
}

/// Sets the current focus subtree to a user-defined tree using an adapter.
///
/// This replaces the entire focused subtree with the provided user tree
/// after converting it to the standard tree representation.
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
  users_tree: user_tree,
  adapter: Adapter(a, user_tree),
) -> Zipper(a) {
  let tree = user_tree_to_standard_tree(users_tree, adapter)
  Zipper(..zipper, focus: tree)
}

/// Updates the value of the current focus node using a transformation function.
///
/// Returns `Ok(zipper)` with the updated value if the focus is a node,
/// or `Error(Nil)` if the focus is a leaf node.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Leaf, Leaf))
/// case update(zipper, fn(x) { x * 2 }) {
///   Ok(zipper) -> get_value(zipper)
///   _ -> Error(Nil)
/// }
/// // => Ok(2)
/// ```
pub fn update(zipper: Zipper(a), updater: fn(a) -> a) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: Leaf) -> Error(Nil)
    Zipper(_, focus: Node(value:, ..) as focus) ->
      Ok(Zipper(..zipper, focus: Node(..focus, value: updater(value))))
  }
}

/// Upserts the current focus node.
///
/// Applies the updater function to the current focus subtree, allowing
/// both updates to existing nodes and insertion of new nodes.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Leaf)
/// let updated_zipper = upsert(zipper, fn(_) { Node(1, Leaf, Leaf) })
///
/// get_value(updated_zipper)
/// // => Ok(1)
/// ```
pub fn upsert(zipper: Zipper(a), updater: fn(Tree(a)) -> Tree(a)) -> Zipper(a) {
  Zipper(..zipper, focus: updater(zipper.focus))
}

/// Sets the left child of the current focus node.
///
/// Returns `Ok(zipper)` with the updated left subtree if the focus is a node,
/// or `Error(Nil)` if the focus is a leaf node.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Leaf, Leaf))
/// let assert Ok(setted_zipper) = set_left(zipper, Node(2, Leaf, Leaf))
/// setted_zipper
/// // => Node(1, Node(2, Leaf, Leaf), Leaf)
/// ```
pub fn set_left(zipper: Zipper(a), left: Tree(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: Leaf) -> Error(Nil)
    Zipper(_, focus: Node(left: _, ..) as focus) ->
      Ok(Zipper(..zipper, focus: Node(..focus, left:)))
  }
}

/// Sets the right child of the current focus node.
///
/// Returns `Ok(zipper)` with the updated right subtree if the focus is a node,
/// or `Error(Nil)` if the focus is a leaf node.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Leaf, Leaf))
/// let assert Ok(setted_zipper) = set_right(zipper, Node(3, Leaf, Leaf))
/// setted_zipper
/// // => Node(1, Leaf, Node(3, Leaf, Leaf))
/// ```
pub fn set_right(zipper: Zipper(a), right: Tree(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: Leaf) -> Error(Nil)
    Zipper(_, focus: Node(right: _, ..) as focus) ->
      Ok(Zipper(..zipper, focus: Node(..focus, right:)))
  }
}

/// Deletes the current focus node, replacing it with a leaf and moving to the parent.
///
/// Returns `Ok(zipper)` focused on the parent node with the current node deleted,
/// or `Error(Nil)` if the focus is the root node (cannot delete root).
///
/// ## Examples
/// ```gleam
/// let tree = Node(1, Node(2, Leaf, Leaf), Leaf)
/// let zipper = from_standard_tree(tree)
///
/// let Ok(zipper) = go_left(zipper)
/// let Ok(zipper) = delete(zipper)
///
/// to_standard_tree(zipper)
/// // => Node(1, Leaf, Leaf)
/// ```
pub fn delete(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case is_root(zipper) {
    True -> Error(Nil)
    False -> Zipper(..zipper, focus: Leaf) |> go_up
  }
}

/// Deletes the left child of the current focus node, replacing it with a leaf.
///
/// Returns `Ok(zipper)` with the left child set to Leaf if the focus is a node,
/// or `Error(Nil)` if the focus is a leaf node.
///
/// ## Examples
/// ```gleam
/// let tree = Node(1, Node(2, Leaf, Leaf), Leaf)
/// let zipper = from_standard_tree(tree)
///
/// let assert Ok(deleted_zipper) = delete_left(zipper)
/// to_standard_tree(deleted_zipper)
/// // => Node(1, Leaf, Leaf)
/// ```
pub fn delete_left(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: Leaf) -> Error(Nil)
    Zipper(_, focus: Node(left: _, ..) as focus) ->
      Ok(Zipper(..zipper, focus: Node(..focus, left: Leaf)))
  }
}

/// Deletes the right child of the current focus node, replacing it with a leaf.
///
/// Returns `Ok(zipper)` with the right child set to Leaf if the focus is a node,
/// or `Error(Nil)` if the focus is a leaf node.
///
/// ## Examples
/// ```gleam
/// let tree = Node(1, Leaf, Node(3, Leaf, Leaf))
/// let zipper = from_standard_tree(tree)
///
/// let assert Ok(deleted_zipper) = delete_right(zipper)
/// to_standard_tree(deleted_zipper)
/// // => Node(1, Leaf, Leaf)
/// ```
pub fn delete_right(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: Leaf) -> Error(Nil)
    Zipper(_, focus: Node(right: _, ..) as focus) ->
      Ok(Zipper(..zipper, focus: Node(..focus, right: Leaf)))
  }
}

/// Checks if the current focus node is the root of the tree.
///
/// Returns `True` if the zipper is at the root (no navigation history),
/// `False` otherwise.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Node(2, Leaf, Leaf), Leaf))
/// is_root(zipper)
/// // => True
///
/// let Ok(child_zipper) = go_left(zipper)
/// is_root(child_zipper)
/// // => False
/// ```
pub fn is_root(zipper: Zipper(a)) -> Bool {
  case zipper {
    Zipper(thread: [], focus: _) -> True
    _ -> False
  }
}

/// Moves the focus to the left child of the current node.
///
/// Returns `Ok(zipper)` focused on the left child if it exists and is not a leaf,
/// or `Error(Nil)` if the left child doesn't exist or is a leaf.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Node(2, Leaf, Leaf), Leaf))
/// case go_left(zipper) {
///   Ok(zipper) -> get_value(zipper)
///   _ -> Error(Nil)
/// }
/// // => Ok(2)
/// ```
pub fn go_left(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: Leaf) | Zipper(_, focus: Node(left: Leaf, ..)) ->
      Error(Nil)
    Zipper(thread:, focus: Node(value:, left:, right:)) ->
      Ok(Zipper(thread: [Left(value:, sibling: right), ..thread], focus: left))
  }
}

/// Moves the focus to the right child of the current node.
///
/// Returns `Ok(zipper)` focused on the right child if it exists and is not a leaf,
/// or `Error(Nil)` if the right child doesn't exist or is a leaf.
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Leaf, Node(3, Leaf, Leaf)))
/// case go_right(zipper) {
///   Ok(zipper) -> get_value(zipper)
///   _ -> Error(Nil)
/// }
/// // => Ok(3)
/// ```
pub fn go_right(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: Leaf) | Zipper(_, focus: Node(right: Leaf, ..)) ->
      Error(Nil)
    Zipper(thread:, focus: Node(value:, left:, right:)) ->
      Ok(Zipper(thread: [Right(value:, sibling: left), ..thread], focus: right))
  }
}

/// Moves the focus to the parent node.
///
/// Returns `Ok(zipper)` focused on the parent node if not at root,
/// or `Error(Nil)` if already at the root (no parent).
///
/// ## Examples
/// ```gleam
/// let zipper = from_standard_tree(Node(1, Node(2, Leaf, Leaf), Leaf))
/// let Ok(child_zipper) = go_left(zipper)
///
/// case go_up(child_zipper) {
///   Ok(parent_zipper) -> get_value(parent_zipper)
///   _ -> Error(Nil)
/// }
/// // => Ok(1)
/// ```
pub fn go_up(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, thread: []) -> Error(Nil)
    Zipper(thread: [Left(value:, sibling: right), ..thread], focus:) ->
      Ok(Zipper(thread:, focus: Node(value:, left: focus, right:)))
    Zipper(thread: [Right(value:, sibling: left), ..thread], focus:) ->
      Ok(Zipper(thread:, focus: Node(value:, left:, right: focus)))
  }
}
