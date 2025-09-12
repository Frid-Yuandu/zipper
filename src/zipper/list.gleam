//// A functional zipper data structure for efficient list navigation and manipulation.
////
//// Provides $O(1)$ operations for insertion, deletion, and updates at the current
//// focus position, with efficient bidirectional navigation. And Provides $O(n)$ operations for
//// converting between lists and zippers, where $n$ is the number of elements in the zipper.
////
//// ## Usage
//// ```gleam
//// import zipper/list
////
//// let zipper = list.from_list([1, 2, 3, 4])
////
//// let assert Ok(zipper) = list.go_right(zipper)
//// let assert Ok(zipper) = list.set(zipper, 99)
//// let zipper = list.insert_left(zipper, 42)
//// let assert Ok(zipper) = list.go_right(zipper)
//// let assert Ok(zipper) = list.delete(zipper)
////
//// list.to_list(zipper)
//// // => [1, 42, 99, 4]
//// ```

import gleam/list
import gleam/option.{type Option, None, Some}

/// A zipper for navigating and manipulating lists.
///
/// Conceptually, a Zipper represents a specific position within a list,
/// effectively partitioning it. It keeps track of the elements that have been
/// traversed (to the left of the "cursor") and the elements that are yet to be
/// seen (at and to the right of the "cursor").
///
/// This structure allows for efficient navigation and modification at any point
/// in the list.
pub opaque type Zipper(a) {
  Zipper(thread: List(a), focus: List(a))
}

/// Create a new empty zipper.
///
/// ## Examples
/// ```gleam
/// new() |> to_list
/// // => []
/// ```
pub fn new() -> Zipper(a) {
  from_list([])
}

/// Create a zipper from a list, with focus on the first element.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3]) |> get
/// // => Ok(1)
/// ```
pub fn from_list(list: List(a)) -> Zipper(a) {
  Zipper(thread: [], focus: list)
}

/// Convert a zipper back to a regular list.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3]) |> to_list
/// // => [1, 2, 3]
/// ```
pub fn to_list(zipper: Zipper(a)) -> List(a) {
  list.reverse(zipper.thread) |> list.append(zipper.focus)
}

/// Get the current focus value of the zipper.
///
/// Returns `Error(Nil)` if the zipper is empty.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3]) |> get
/// // => Ok(1)
///
/// new() |> get
/// // => Error(Nil)
/// ```
pub fn get(zipper: Zipper(a)) -> Result(a, Nil) {
  case zipper {
    Zipper(focus: [], ..) -> Error(Nil)
    Zipper(focus: [current, ..], ..) -> Ok(current)
  }
}

/// Insert a new value to the left of the current focus value.
///
/// If the zipper is empty, the new value becomes the focus. If the zipper is not empty,
/// the new value is inserted before the current focus value.
///
/// ## Examples
/// ```gleam
/// from_list([2, 3])
/// |> insert_left(1)
/// |> to_list
/// // => [1, 2, 3]
///
/// from_list([2, 3])
/// |> insert_left(1)
/// |> get
/// // => Ok(2)
///
/// from_list([])
/// |> insert_left(42)
/// |> get
/// // => Ok(42)
/// ```
pub fn insert_left(zipper: Zipper(a), value: a) -> Zipper(a) {
  case zipper {
    Zipper(thread: [], focus: []) -> Zipper(thread: [], focus: [value])
    Zipper(thread: thread, focus: focus) ->
      Zipper(thread: [value, ..thread], focus: focus)
  }
}

/// Insert a new value to the right of the current focus value.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2])
/// |> insert_right(3)
/// |> to_list
/// // => [1, 3, 2]
/// ```
pub fn insert_right(zipper: Zipper(a), value: a) -> Zipper(a) {
  case zipper {
    Zipper(_, focus: []) -> Zipper(..zipper, focus: [value])
    Zipper(_, focus: [head, ..rest]) ->
      Zipper(..zipper, focus: [head, ..[value, ..rest]])
  }
}

/// Set the current focus value of the zipper list.
///
/// Returns the previous value if successful, or `Error(Nil)` if the zipper is empty.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3])
/// |> set(99)
/// |> result.map(to_list)
/// // => Ok([99, 2, 3])
/// ```
pub fn set(zipper: Zipper(a), new_value: a) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: []) -> Error(Nil)
    Zipper(_, focus: [_, ..rest]) ->
      Ok(Zipper(..zipper, focus: [new_value, ..rest]))
  }
}

/// Update the current focus value of the zipper list using a transformation function.
///
/// Returns the previous value if successful, or `Error(Nil)` if the zipper is empty.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3])
/// |> update(fn(x) { x * 2 })
/// |> result.map(to_list)
/// // => Ok([2, 2, 3])
/// ```
pub fn update(zipper: Zipper(a), updater: fn(a) -> a) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(_, focus: []) -> Error(Nil)
    Zipper(_, focus: [current, ..rest]) ->
      Ok(Zipper(..zipper, focus: [updater(current), ..rest]))
  }
}

/// Update or insert a value at the current focus position.
///
/// If the zipper is empty, inserts a new value. If the zipper has a focus,
/// updates the current value using the transformation function.
///
/// The updater function receives the current focus value as `Some(value)`
/// if present, or `None` if the zipper is empty.
///
/// ## Examples
/// ```gleam
/// // Update existing value
/// from_list([1, 2, 3])
/// |> upsert(fn(Some(x)) { x * 2 })
/// |> to_list
/// // => [2, 2, 3]
///
/// // Insert when empty
/// new()
/// |> upsert(fn(None) { 42 })
/// |> to_list
/// // => [42]
/// ```
pub fn upsert(zipper: Zipper(a), updater: fn(Option(a)) -> a) -> Zipper(a) {
  case zipper {
    Zipper(_, focus: []) -> {
      let value = updater(None)
      Zipper(..zipper, focus: [value])
    }
    Zipper(_, focus: [current, ..rest]) -> {
      let value = updater(Some(current))
      Zipper(..zipper, focus: [value, ..rest])
    }
  }
}

/// Delete the current focus value from the zipper.
///
/// Returns a new zipper with focus moved to the next element, or `Error(Nil)` if empty.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3])
/// |> delete()
/// |> to_list
/// // => [2, 3]
/// ```
pub fn delete(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(focus: [], ..) -> Error(Nil)
    Zipper(_, focus: [_, ..focus]) -> Ok(Zipper(..zipper, focus:))
  }
}

/// Check if the zipper is empty (contains no elements).
///
/// ## Examples
/// ```gleam
/// new() |> is_empty
/// // => True
///
/// from_list([1]) |> is_empty
/// // => False
/// ```
pub fn is_empty(zipper: Zipper(a)) -> Bool {
  case zipper {
    Zipper(thread: [], focus: []) -> True
    _ -> False
  }
}

/// Check if the current focus is the leftmost element in the zipper list.
///
/// Returns `True` if there are no elements to the left of the current focus.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3]) |> is_leftmost
/// // => True
///
/// from_list([1, 2, 3]) |> go_right() |> is_leftmost
/// // => False
/// ```
pub fn is_leftmost(zipper: Zipper(a)) -> Bool {
  case zipper {
    Zipper(thread: [], ..) -> True
    _ -> False
  }
}

/// Check if the current focus is the rightmost element in the zipper list.
///
/// Returns `True` if there are no elements to the right of the current focus.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3]) |> go_right() |> go_right() |> is_rightmost
/// // => True
///
/// from_list([1, 2, 3]) |> is_rightmost
/// // => False
/// ```
pub fn is_rightmost(zipper: Zipper(a)) -> Bool {
  case zipper {
    Zipper(focus: [], ..) | Zipper(focus: [_], ..) -> True
    _ -> False
  }
}

/// Move the focus one position to the left.
///
/// Returns a new zipper with focus moved left, or `Error(Nil)` if already at leftmost.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3])
/// |> go_right()
/// |> go_left()
/// |> get
/// // => Ok(1)
/// ```
pub fn go_left(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(thread: [], ..) -> Error(Nil)
    Zipper(thread: [value, ..thread], focus:) ->
      Ok(Zipper(thread:, focus: [value, ..focus]))
  }
}

/// Move the focus one position to the right.
///
/// Returns a new zipper with focus moved right, or `Error(Nil)` if already at rightmost.
///
/// ## Examples
/// ```gleam
/// from_list([1, 2, 3])
/// |> go_right()
/// |> get
/// // => Ok(2)
/// ```
pub fn go_right(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(focus: [], ..) -> Error(Nil)
    Zipper(focus: [value, ..focus], thread:) ->
      Ok(Zipper(thread: [value, ..thread], focus:))
  }
}
