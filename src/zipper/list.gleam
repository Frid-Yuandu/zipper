//// A functional zipper data structure for efficient list navigation and manipulation.
////
//// Provides $O(1)$ operations for insertion, deletion, and updates at the current
//// focus position, with efficient bidirectional navigation. And Provides $O(n)$ operations for
//// converting between lists and zippers, where $n$ is the number of elements in the zipper.
////
//// ## Usage
//// ```gleam
//// import zipper/list as zipper_list
////
//// let zipper = zipper_list.from_list([1, 2, 3, 4])
////
//// let assert Ok(zipper) = zipper_list.go_right(zipper)
//// let assert Ok(zipper) = zipper_list.set_value(zipper, 99)
//// let zipper = zipper_list.insert_left(zipper, 42)
//// let assert Ok(zipper) = zipper_list.go_right(zipper)
//// let assert Ok(zipper) = zipper_list.delete(zipper)
////
//// zipper_list.to_list(zipper)
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
/// let empty = new()
/// to_list(empty)
/// // => []
/// ```
pub fn new() -> Zipper(a) {
  from_list([])
}

/// Create a zipper from a list, with focus on the first element.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2, 3])
/// get_value(zipper)
/// // => Ok(1)
/// ```
pub fn from_list(list: List(a)) -> Zipper(a) {
  Zipper(thread: [], focus: list)
}

/// Convert a zipper back to a regular list.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2, 3])
/// to_list(zipper)
/// // => [1, 2, 3]
/// ```
pub fn to_list(zipper: Zipper(a)) -> List(a) {
  list.reverse(zipper.thread) |> list.append(zipper.focus)
}

/// Get the current focus value of the zipper.
///
/// **Deprecated**: Use [`get_value`](#get_value) instead.
///
/// Returns `Error(Nil)` if the zipper is empty.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2, 3])
/// get_value(zipper)
/// // => Ok(1)
///
/// let empty = new()
/// get_value(empty)
/// // => Error(Nil)
/// ```
@deprecated("Use `get_value` instead")
pub fn get(zipper: Zipper(a)) -> Result(a, Nil) {
  get_value(zipper)
}

/// Get the current focus value of the zipper.
///
/// Returns `Error(Nil)` if the zipper is empty.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2, 3])
/// get_value(zipper)
/// // => Ok(1)
///
/// let empty = new()
/// get_value(empty)
/// // => Error(Nil)
/// ```
pub fn get_value(zipper: Zipper(a)) -> Result(a, Nil) {
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
/// let zipper =
///   from_list([2, 3])
///   |> insert_left(1)
/// to_list(zipper)
/// // => [1, 2, 3]
/// get_value(zipper)
/// // => Ok(2)
///
/// let empty = from_list([])
/// let zipper = insert_left(empty, 42)
/// get_value(zipper)
/// // => Ok(42)
/// ```
pub fn insert_left(zipper: Zipper(a), value: a) -> Zipper(a) {
  case zipper {
    Zipper(thread: [], focus: []) -> Zipper(thread: [], focus: [value])
    Zipper(thread:, focus:) -> Zipper(thread: [value, ..thread], focus:)
  }
}

/// Insert a new value to the right of the current focus value.
/// If the original zipper is empty, the new value becomes the focus;
/// otherwise, the original focus remains unchanged.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2])
/// let zipper = insert_right(zipper, 3)
/// to_list(zipper)
/// // => [1, 3, 2]
/// get_value(zipper)
/// // => Ok(1)
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
/// **Deprecated**: Use [`set_value`](#set_value) instead.
///
/// Returns the previous value if successful, or `Error(Nil)` if the zipper is empty.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2, 3])
/// let assert Ok(updated) = set_value(zipper, 99)
/// to_list(updated)
/// // => [99, 2, 3]
/// ```
@deprecated("Use `set_value` instead")
pub fn set(zipper: Zipper(a), new_value: a) -> Result(Zipper(a), Nil) {
  set_value(zipper, new_value)
}

/// Set the current focus value of the zipper list.
///
/// Returns the previous value if successful, or `Error(Nil)` if the zipper is empty.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2, 3])
/// let assert Ok(updated) = set_value(zipper, 99)
/// to_list(updated)
/// // => [99, 2, 3]
/// ```
pub fn set_value(zipper: Zipper(a), new_value: a) -> Result(Zipper(a), Nil) {
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
/// let zipper = from_list([1, 2, 3])
/// let assert Ok(updated) = update(zipper, fn(x) { x * 2 })
/// to_list(updated)
/// // => [2, 2, 3]
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
/// let transform = fn(x) {
///   case x {
///     Some(value) -> value * 2
///     None -> 42
///   }
/// }
///
/// // Update existing value
/// let zipper = from_list([1, 2, 3])
/// let zipper = upsert(zipper, transform)
/// to_list(zipper)
/// // => [2, 2, 3]
///
/// // Insert when empty
/// let empty = new()
/// let zipper = upsert(empty, transform)
/// to_list(zipper)
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

/// Delete the current focus element from the zipper.
///
/// The focus moves to the right element if it exists, otherwise to the left
/// element.
///
/// Returns `Ok(zipper)` with the focus moved to the new location.
/// Returns `Error(Nil)` if the zipper is empty or contains only one element.
///
/// This operation is prevented when the zipper has only one element to ensure
/// the zipper never becomes empty without a focus.
///
/// ## Examples
/// ```gleam
/// // Successful deletion with multiple elements
/// let zipper = from_list([1, 2, 3])
/// let assert Ok(zipper) = delete(zipper)
/// to_list(zipper)
/// // => [2, 3]
///
/// // Error when trying to delete the only element
/// let single = from_list([42])
/// delete(single)
/// // => Error(Nil)
/// ```
pub fn delete(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(focus: [], ..) | Zipper(thread: [], focus: [_]) -> Error(Nil)
    Zipper(thread: [value, ..thread], focus: [_]) ->
      Ok(Zipper(thread:, focus: [value]))
    Zipper(_, focus: [_, ..focus]) -> Ok(Zipper(..zipper, focus:))
  }
}

/// Check if the zipper is empty (contains no elements).
///
/// ## Examples
/// ```gleam
/// let empty = new()
/// is_empty(empty)
/// // => True
///
/// let zipper = from_list([1])
/// is_empty(zipper)
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
/// let zipper = from_list([1, 2, 3])
/// is_leftmost(zipper)
/// // => True
///
/// let zipper = from_list([1, 2, 3])
/// let assert Ok(moved) = go_right(zipper)
/// is_leftmost(moved)
/// // => False
/// ```
pub fn is_leftmost(zipper: Zipper(a)) -> Bool {
  case zipper.thread {
    [] -> True
    _ -> False
  }
}

/// Check if the current focus is the rightmost element in the zipper list.
///
/// Returns `True` if there are no elements to the right of the current focus.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2, 3])
/// is_rightmost(zipper)
/// // => False
///
/// let zipper = from_list([1, 2, 3])
/// let assert Ok(moved) = go_right(zipper)
/// let assert Ok(rightmost) = go_right(moved)
/// is_rightmost(rightmost)
/// // => True
/// ```
pub fn is_rightmost(zipper: Zipper(a)) -> Bool {
  case zipper.focus {
    [] | [_] -> True
    _ -> False
  }
}

/// Move the focus one position to the left.
///
/// Returns a new zipper with focus moved left, or `Error(Nil)` if already at leftmost.
///
/// ## Examples
/// ```gleam
/// let zipper = from_list([1, 2, 3])
/// let assert Ok(moved) = go_right(zipper)
/// let assert Ok(returned) = go_left(moved)
/// get_value(returned)
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
/// let zipper = from_list([1, 2, 3])
/// let assert Ok(moved) = go_right(zipper)
/// get_value(moved)
/// // => Ok(2)
/// ```
pub fn go_right(zipper: Zipper(a)) -> Result(Zipper(a), Nil) {
  case zipper {
    Zipper(focus: [], ..) | Zipper(focus: [_], ..) -> Error(Nil)
    Zipper(focus: [value, ..focus], thread:) ->
      Ok(Zipper(thread: [value, ..thread], focus:))
  }
}
