import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleeunit/should
import qcheck
import zipper/list as zlist

// Main module documentation example
pub fn doc_example_comprehensive_operations_test() {
  let z = zlist.from_list([1, 2, 3, 4])

  let assert Ok(new_z) =
    z
    |> zlist.go_right()
    |> result.try(zlist.set(_, 99))
    |> result.map(zlist.insert_left(_, 42))
    |> result.try(zlist.go_right)
    |> result.try(zlist.delete)

  assert new_z |> zlist.to_list == [1, 42, 99, 4]
}

// from_list examples
pub fn doc_example_from_list_get_first_element_test() {
  let z = zlist.from_list([1, 2, 3])
  assert zlist.get(z) == Ok(1)
}

pub fn doc_example_from_list_to_list_test() {
  let z = zlist.from_list([1, 2, 3])
  assert zlist.to_list(z) == [1, 2, 3]
}

// new() examples
pub fn doc_example_new_empty_list_test() {
  let z = zlist.new()
  assert zlist.to_list(z) == []
}

// get() examples
pub fn doc_example_get_from_non_empty_test() {
  let z = zlist.from_list([1, 2, 3])
  assert zlist.get(z) == Ok(1)
}

pub fn doc_example_get_from_empty_test() {
  let z = zlist.new()
  assert zlist.get(z) == Error(Nil)
}

// insert_left() examples
pub fn doc_example_insert_left_non_empty_test() {
  let z =
    zlist.from_list([2, 3])
    |> zlist.insert_left(1)
  assert zlist.to_list(z) == [1, 2, 3]
}

pub fn doc_example_insert_left_preserves_focus_test() {
  let z =
    zlist.from_list([2, 3])
    |> zlist.insert_left(1)
  assert zlist.get(z) == Ok(2)
}

pub fn doc_example_insert_left_into_empty_test() {
  let z =
    zlist.new()
    |> zlist.insert_left(42)
  assert zlist.get(z) == Ok(42)
}

// insert_right() examples
pub fn doc_example_insert_right_test() {
  let z =
    zlist.from_list([1, 2])
    |> zlist.insert_right(3)
  assert zlist.to_list(z) == [1, 3, 2]
}

// set() examples
pub fn doc_example_set_value_test() {
  let z = zlist.from_list([1, 2, 3])
  let assert Ok(new_z) = zlist.set(z, 99)
  assert zlist.to_list(new_z) == [99, 2, 3]
}

// update() examples
pub fn doc_example_update_value_test() {
  let z = zlist.from_list([1, 2, 3])
  let assert Ok(new_z) = zlist.update(z, fn(x) { x * 2 })
  assert zlist.to_list(new_z) == [2, 2, 3]
}

// upsert() examples
pub fn doc_example_upsert_update_existing_test() {
  let z = zlist.from_list([1, 2, 3])
  let new_z =
    zlist.upsert(z, fn(x: Option(Int)) {
      case x {
        Some(old) -> 2 * old
        None -> 42
      }
    })
  assert zlist.to_list(new_z) == [2, 2, 3]
}

pub fn doc_example_upsert_insert_when_empty_test() {
  let z = zlist.new()
  let new_z =
    zlist.upsert(z, fn(x: Option(Int)) {
      case x {
        Some(old) -> 2 * old
        None -> 42
      }
    })
  assert zlist.to_list(new_z) == [42]
}

// delete() examples
pub fn doc_example_delete_element_test() {
  let z = zlist.from_list([1, 2, 3])
  let assert Ok(new_z) = zlist.delete(z)
  assert zlist.to_list(new_z) == [2, 3]
}

// is_empty() examples
pub fn doc_example_is_empty_new_test() {
  let z = zlist.new()
  assert zlist.is_empty(z) == True
}

pub fn doc_example_is_empty_with_elements_test() {
  let z = zlist.from_list([1])
  assert zlist.is_empty(z) == False
}

// is_leftmost() examples
pub fn doc_example_is_leftmost_beginning_test() {
  let z = zlist.from_list([1, 2, 3])
  assert zlist.is_leftmost(z) == True
}

pub fn doc_example_is_leftmost_after_moving_right_test() {
  let z = zlist.from_list([1, 2, 3])
  let assert Ok(moved_z) = zlist.go_right(z)
  assert zlist.is_leftmost(moved_z) == False
}

// is_rightmost() examples
pub fn doc_example_is_rightmost_end_test() {
  let z = zlist.from_list([1, 2, 3])
  let assert Ok(z1) = zlist.go_right(z)
  let assert Ok(z2) = zlist.go_right(z1)
  assert zlist.is_rightmost(z2) == True
}

pub fn doc_example_is_rightmost_beginning_test() {
  let z = zlist.from_list([1, 2, 3])
  assert zlist.is_rightmost(z) == False
}

// go_left() examples
pub fn doc_example_go_left_and_back_test() {
  let z = zlist.from_list([1, 2, 3])
  let assert Ok(right_z) = zlist.go_right(z)
  let assert Ok(left_z) = zlist.go_left(right_z)
  assert zlist.get(left_z) == Ok(1)
}

// go_right() examples
pub fn doc_example_go_right_test() {
  let z = zlist.from_list([1, 2, 3])
  let assert Ok(right_z) = zlist.go_right(z)
  assert zlist.get(right_z) == Ok(2)
}

//
// property-based testing
//

/// Round-trip conversion preserves list identity.
/// Converting a list to a zipper and back to a list should result in the original list.
///
/// Formula: $\forall l: \text{List} \Rightarrow \text{to\_list}(\text{from\_list}(l)) = l$
pub fn round_trip_conversion_identity_test() {
  use list <- qcheck.given(maybe_empty_integer_list())
  let new_list = zlist.from_list(list) |> zlist.to_list()
  assert list == new_list
}

/// Moving right then left returns to the original position.
/// For any list with at least two elements, going right then left should return to the original zipper state.
///
/// Formula: $\forall l: \text{List}, |l| \geq 2 \Rightarrow \text{go\_left}(\text{go\_right}(\text{from\_list}(l))) = \text{from\_list}(l)$
pub fn go_right_is_invertible_test() {
  use list <- qcheck.given(list_of_at_least_two_integers())
  let zipper = zlist.from_list(list)
  let assert Ok(navigated_zipper) =
    zipper |> zlist.go_right() |> result.try(zlist.go_left)

  assert navigated_zipper == zipper
}

/// Moving left then right returns to the original position.
/// For any list with at least two elements, going left then right from the rightmost position should return to the original zipper state.
///
/// Formula: $\forall l: \text{List}, |l| \geq 2 \Rightarrow \text{go\_right}(\text{go\_left}(\text{rightmost}(\text{from\_list}(l)))) = \text{rightmost}(\text{from\_list}(l))$
pub fn go_left_is_invertible_test() {
  use list <- qcheck.given(list_of_at_least_two_integers())

  let zipper = zlist.from_list(list) |> go_to_the_rightmost()
  let assert Ok(navigated_zipper) =
    zipper |> zlist.go_left() |> result.try(zlist.go_right)
  assert navigated_zipper == zipper
}

/// Moving right when at the rightmost position should fail.
/// For any zipper that is at the rightmost position, attempting to move right should result in an error.
///
/// Formula: $\forall z: \text{ZipperList} \; \text{where} \; \text{is\_rightmost}(z) \Rightarrow \text{go\_right}(z) \; \text{is} \; \text{Error}$
pub fn go_right_when_rightmost_is_an_error_test() {
  use list <- qcheck.given(maybe_empty_integer_list())

  let rightmost_zipper = zlist.from_list(list) |> go_to_the_rightmost
  assert zlist.go_right(rightmost_zipper) == Error(Nil)
}

fn go_to_the_rightmost(zipper: zlist.Zipper(a)) -> zlist.Zipper(a) {
  case zlist.is_rightmost(zipper) {
    True -> zipper
    False -> {
      let assert Ok(zipper) = zlist.go_right(zipper)
      go_to_the_rightmost(zipper)
    }
  }
}

/// Moving left when at the leftmost position should fail.
/// For any zipper that is at the leftmost position, attempting to move left should result in an error.
///
/// Formula: $\forall z: \text{ZipperList} \; \text{where} \; \text{is\_leftmost}(z) \Rightarrow \text{go\_left}(z) \; \text{is} \; \text{Error}$
pub fn go_left_when_leftmost_is_an_error_test() {
  use list <- qcheck.given(maybe_empty_integer_list())
  let zipper = zlist.from_list(list)
  assert zlist.go_left(zipper) == Error(Nil)
}

/// Setting a value makes it immediately visible.
/// When setting a new value in a non-empty zipper, the get function should return that same value.
///
/// Formula: $\forall l: \text{List}, l \neq [], v: a \Rightarrow \text{get}(\text{set}(\text{from\_list}(l), v)) = v$
pub fn set_is_immediately_visible_test() {
  use list <- qcheck.given(non_empty_integer_list())
  use new_value <- qcheck.given(qcheck.uniform_int())

  let assert Ok(got_value) =
    zlist.from_list(list) |> zlist.set(new_value) |> result.try(zlist.get)
  assert got_value == new_value
}

/// Updating a value applies the function correctly.
/// When updating a zipper with a function, the get function should return the result of applying that function to the original value.
///
/// Formula: $\forall v: a, f: a \rightarrow a \Rightarrow \text{get}(\text{update}(\text{from\_list}([v]), f)) = f(v)$
pub fn update_is_immediately_visible_test() {
  use value <- qcheck.given(qcheck.uniform_int())
  let updater = fn(x) { x * 2 }

  let assert Ok(updated_value) =
    zlist.from_list([value]) |> zlist.update(updater) |> result.try(zlist.get)
  assert updated_value == updater(value)
}

/// Upsert on existing element applies the update function.
/// When upserting on a non-empty zipper, the function should be applied to the existing value (Some(x)).
///
/// Formula: $\forall v: a, f: \text{Option}(a) \rightarrow a \Rightarrow \text{get}(\text{upsert}(\text{from\_list}([v]), f)) = f(\text{Some}(v))$
pub fn upsert_on_existing_applies_update_function_test() {
  use value <- qcheck.given(qcheck.uniform_int())
  let upserter = fn(x) {
    case x {
      Some(x) -> x * 2
      None -> panic as "should not be reach"
    }
  }

  let assert Ok(upserted_value) =
    zlist.from_list([value]) |> zlist.upsert(upserter) |> zlist.get()
  assert upserted_value == upserter(Some(value))
}

/// Upsert on empty list inserts the given value.
/// When upserting on an empty zipper, the function should be applied to None and the result should be inserted as a single element.
///
/// Formula: $\forall v: a, f: \text{Option}(a) \rightarrow a \Rightarrow \text{to\_list}(\text{upsert}(\text{from\_list}([]), f)) = [f(\text{None})]$
pub fn upsert_on_empty_inserts_given_value_test() {
  use value <- qcheck.given(qcheck.uniform_int())
  let upserter = fn(x) {
    case x {
      Some(_) -> panic as "should not be reach"
      None -> value
    }
  }

  let upserted_list =
    zlist.from_list([]) |> zlist.upsert(upserter) |> zlist.to_list()
  assert upserted_list == [value]
}

/// Insert left makes the value immediately visible to the left.
/// When inserting a value to the left, moving left should reveal that same value.
///
/// Formula: $\forall l: \text{List}, l \neq [], v: a \Rightarrow \text{get}(\text{go\_left}(\text{insert\_left}(\text{from\_list}(l), v))) = v$
pub fn insert_left_is_immediately_visible_test() {
  use list <- qcheck.given(non_empty_integer_list())
  use value <- qcheck.given(qcheck.uniform_int())

  let assert Ok(got_value) =
    zlist.from_list(list)
    |> zlist.insert_left(value)
    |> zlist.go_left
    |> result.try(zlist.get)

  assert got_value == value
}

/// Insert right makes the value immediately visible to the right.
/// When inserting a value to the right, moving right should reveal that same value.
///
/// Formula: $\forall l: \text{List}, l \neq [], v: a \Rightarrow \text{get}(\text{go\_right}(\text{insert\_right}(\text{from\_list}(l), v))) = v$
pub fn insert_right_is_immediately_visible_test() {
  use list <- qcheck.given(non_empty_integer_list())
  use value <- qcheck.given(qcheck.uniform_int())

  let assert Ok(zipper) =
    zlist.from_list(list) |> zlist.insert_right(value) |> zlist.go_right
  let assert Ok(got_value) = zlist.get(zipper)

  assert got_value == value
}

/// Insert left on non-empty zipper preserves the original focus.
/// When inserting a value to the left of a non-empty zipper, the focus should remain on the original element.
///
/// Formula: $\forall l: \text{List}, l \neq [], v: a \Rightarrow \text{get}(\text{insert\_left}(\text{from\_list}(l), v)) = \text{first}(l)$
pub fn insert_left_on_non_empty_preserves_focus_test() {
  use list <- qcheck.given(non_empty_integer_list())
  use value <- qcheck.given(qcheck.uniform_int())
  let assert [original_value, ..] = list
  let zipper = zlist.from_list(list) |> zlist.insert_left(value)
  let assert Ok(got_value) = zlist.get(zipper)

  assert got_value == original_value
}

/// Insert right on non-empty zipper preserves the original focus.
/// When inserting a value to the right of a non-empty zipper, the focus should remain on the original element.
///
/// Formula: $\forall l: \text{List}, l \neq [], v: a \Rightarrow \text{get}(\text{insert\_right}(\text{from\_list}(l), v)) = \text{first}(l)$
pub fn insert_right_on_non_empty_preserves_focus_test() {
  use list <- qcheck.given(non_empty_integer_list())
  use value <- qcheck.given(qcheck.uniform_int())
  let assert [original_value, ..] = list
  let zipper = zlist.from_list(list) |> zlist.insert_right(value)
  let assert Ok(got_value) = zlist.get(zipper)

  assert got_value == original_value
}

/// Deleting from an empty list should always result in an error.
/// When attempting to delete from an empty zipper, the operation should fail.
///
/// Formula: $\text{delete}(\text{from\_list}([])) \; \text{is} \; \text{Error}$
pub fn delete_from_empty_list_is_an_error_test() {
  let zipper = zlist.from_list([])
  assert zlist.delete(zipper) == Error(Nil)
}

/// Deleting an element from a non-empty list with at least two elements reduces its size by one.
/// For any list with at least two elements, the length of the list after deleting an element should be the original length minus one.
///
/// Formula: $\forall l: \text{List}, |l| \geq 2 \Rightarrow \text{length}(\text{to\_list}(\text{delete}(\text{from\_list}(l)))) = \text{length}(l) - 1$
pub fn delete_reduces_list_size_by_one_test() {
  use original_list <- qcheck.given(list_of_at_least_two_integers())
  let original_size = list.length(original_list)

  let assert Ok(deleted_zipper) = zlist.from_list(original_list) |> zlist.delete
  let new_size = deleted_zipper |> zlist.to_list |> list.length

  assert new_size == original_size - 1
}

/// Deleting the only element in a list results in an error.
/// For any single-element list, deleting that element should result in an error to prevent having an empty zipper with no focus.
///
/// Formula: $\forall x: a \Rightarrow \text{delete}(\text{from\_list}([x])) \; \text{is} \; \text{Error}$
pub fn delete_the_only_element_is_an_error_test() {
  use value <- qcheck.given(qcheck.uniform_int())
  let zipper = zlist.from_list([value])

  assert zlist.delete(zipper) == Error(Nil)
}

/// When deleting an element that is not the rightmost, the focus should move to the element that was originally to its right.
/// For any list with at least two elements, deleting the first element should focus on the second element.
///
/// Formula: $\forall l: \text{List}, |l| \geq 2 \Rightarrow \text{get}(\text{delete}(\text{from\_list}(l))) = \text{second}(l)$
pub fn delete_moves_focus_to_the_right_test() {
  use original_list <- qcheck.given(list_of_at_least_two_integers())
  let assert [_, expected_focus_value, ..] = original_list

  let zipper = zlist.from_list(original_list)
  let assert Ok(deleted_zipper) = zipper |> zlist.delete
  let assert Ok(new_focus_value) = zlist.get(deleted_zipper)

  assert new_focus_value == expected_focus_value
}

/// When deleting the rightmost element, the focus should move to the new rightmost element (the one that was originally to its left).
/// For any list with at least two elements, deleting the rightmost element should focus on the new rightmost element.
///
/// Formula: $\forall l: \text{List}, |l| \geq 2 \Rightarrow \text{get}(\text{delete}(\text{rightmost}(\text{from\_list}(l)))) = \text{second\_to\_last}(l)$
pub fn delete_at_rightmost_moves_focus_to_the_left_test() {
  use original_list <- qcheck.given(list_of_at_least_two_integers())
  let assert [_, expected_focus_value, ..] = list.reverse(original_list)

  let zipper = zlist.from_list(original_list) |> go_to_the_rightmost
  let assert Ok(deleted_zipper) = zlist.delete(zipper)
  let assert Ok(new_focus_value) = zlist.get(deleted_zipper)

  assert new_focus_value == expected_focus_value
}

/// Getting from an empty zipper should always result in an error.
/// For any attempt to get a value from an empty zipper, the operation should fail.
///
/// Formula: $\text{get}(\text{from\_list}([])) \; \text{is} \; \text{Error}$
pub fn get_from_empty_list_is_error_test() {
  let zipper = zlist.from_list([])
  assert zlist.get(zipper) == Error(Nil)
}

/// Getting from a non-empty zipper should return the focused value.
/// For any non-empty list, getting from the zipper should return the first element.
///
/// Formula: $\forall l: \text{List}, l \neq [] \Rightarrow \text{get}(\text{from\_list}(l)) = \text{first}(l)$
pub fn get_from_non_empty_list_returns_value_test() {
  use list <- qcheck.given(non_empty_integer_list())
  let assert [expected_value, ..] = list
  let zipper = zlist.from_list(list)
  let assert Ok(got_value) = zlist.get(zipper)

  assert got_value == expected_value
}

/// Inserting left on an empty list should focus on the inserted element.
/// When inserting a value to the left of an empty zipper, the get operation should return that value.
///
/// Formula: $\forall v: a \Rightarrow \text{get}(\text{insert\_left}(\text{from\_list}([]), v)) = v$
pub fn insert_left_on_empty_list_focuses_on_inserted_element_test() {
  use value <- qcheck.given(qcheck.uniform_int())
  let zipper = zlist.from_list([]) |> zlist.insert_left(value)
  let assert Ok(got_value) = zlist.get(zipper)

  assert got_value == value
}

/// Inserting right on an empty list should focus on the inserted element.
/// When inserting a value to the right of an empty zipper, the get operation should return that value.
///
/// Formula: $\forall v: a \Rightarrow \text{get}(\text{insert\_right}(\text{from\_list}([]), v)) = v$
pub fn insert_right_on_empty_list_focuses_on_inserted_element_test() {
  use value <- qcheck.given(qcheck.uniform_int())
  let zipper = zlist.from_list([]) |> zlist.insert_right(value)
  let assert Ok(got_value) = zlist.get(zipper)

  assert got_value == value
}

/// Insert left increases zipper length by one.
/// For any list, inserting a value to the left should increase the length by one.
///
/// Formula: $\forall l: \text{List}, v: a \Rightarrow \text{length}(\text{to\_list}(\text{insert\_left}(\text{from\_list}(l), v))) = \text{length}(l) + 1$
pub fn insert_left_increases_length_by_one_test() {
  use list <- qcheck.given(maybe_empty_integer_list())
  use value <- qcheck.given(qcheck.uniform_int())
  let original_length = list.length(list)
  let new_zipper = zlist.from_list(list) |> zlist.insert_left(value)
  let new_length = new_zipper |> zlist.to_list |> list.length

  assert new_length == original_length + 1
}

/// Insert right increases zipper length by one.
/// For any list, inserting a value to the right should increase the length by one.
///
/// Formula: $\forall l: \text{List}, v: a \Rightarrow \text{length}(\text{to\_list}(\text{insert\_right}(\text{from\_list}(l), v))) = \text{length}(l) + 1$
pub fn insert_right_increases_length_by_one_test() {
  use list <- qcheck.given(maybe_empty_integer_list())
  use value <- qcheck.given(qcheck.uniform_int())
  let original_length = list.length(list)
  let new_zipper = zlist.from_list(list) |> zlist.insert_right(value)
  let new_length = new_zipper |> zlist.to_list |> list.length

  assert new_length == original_length + 1
}

/// Set operation preserves zipper length.
/// For any non-empty list, setting a value should not change the length.
///
/// Formula: $\forall l: \text{List}, l \neq [], v: a \Rightarrow \text{length}(\text{to\_list}(\text{set}(\text{from\_list}(l), v))) = \text{length}(l)$
pub fn set_preserves_length_test() {
  use list <- qcheck.given(non_empty_integer_list())
  use value <- qcheck.given(qcheck.uniform_int())
  let original_length = list.length(list)
  let assert Ok(new_zipper) = zlist.from_list(list) |> zlist.set(value)
  let new_length = new_zipper |> zlist.to_list |> list.length

  assert new_length == original_length
}

/// Update operation preserves zipper length.
/// For any non-empty list, updating a value should not change the length.
///
/// Formula: $\forall l: \text{List}, l \neq [], f: a \rightarrow a \Rightarrow \text{length}(\text{to\_list}(\text{update}(\text{from\_list}(l), f))) = \text{length}(l)$
pub fn update_preserves_length_test() {
  use list <- qcheck.given(non_empty_integer_list())
  let updater = fn(x) { x * 2 }
  let original_length = list.length(list)
  let assert Ok(new_zipper) = zlist.from_list(list) |> zlist.update(updater)
  let new_length = new_zipper |> zlist.to_list |> list.length

  assert new_length == original_length
}

/// Upsert on existing element preserves zipper length.
/// For any non-empty list, upserting with a value should not change the length.
///
/// Formula: $\forall l: \text{List}, l \neq [], f: \text{Option}(a) \rightarrow a \Rightarrow \text{length}(\text{to\_list}(\text{upsert}(\text{from\_list}(l), f))) = \text{length}(l)$
pub fn upsert_on_existing_preserves_length_test() {
  use list <- qcheck.given(non_empty_integer_list())
  let upserter = fn(x) {
    case x {
      Some(x) -> x * 2
      None -> panic as "should not be reach"
    }
  }
  let original_length = list.length(list)
  let new_zipper = zlist.from_list(list) |> zlist.upsert(upserter)
  let new_length = new_zipper |> zlist.to_list |> list.length

  assert new_length == original_length
}

/// Is empty returns True on empty zipper.
/// For an empty zipper, the is_empty function should return True.
///
/// Formula: $\text{is\_empty}(\text{from\_list}([])) = \text{True}$
pub fn is_empty_on_empty_list_returns_true_test() {
  let zipper = zlist.from_list([])
  assert zlist.is_empty(zipper) == True
}

/// Is empty returns False on non-empty zipper.
/// For any non-empty list, the is_empty function should return False.
///
/// Formula: $\forall l: \text{List}, l \neq [] \Rightarrow \text{is\_empty}(\text{from\_list}(l)) = \text{False}$
pub fn is_empty_on_non_empty_list_returns_false_test() {
  use list <- qcheck.given(non_empty_integer_list())
  let zipper = zlist.from_list(list)
  assert zlist.is_empty(zipper) == False
}

/// Is leftmost returns True on newly created zipper.
/// For any list created with from_list, the is_leftmost function should return True.
///
/// Formula: $\forall l: \text{List} \Rightarrow \text{is\_leftmost}(\text{from\_list}(l)) = \text{True}$
pub fn is_leftmost_on_from_list_returns_true_test() {
  use list <- qcheck.given(maybe_empty_integer_list())
  let zipper = zlist.from_list(list)
  assert zlist.is_leftmost(zipper) == True
}

/// Is rightmost returns True on empty zipper.
/// For an empty zipper, the is_rightmost function should return True.
///
/// Formula: $\forall l: \left( l = [] \lor \left( \exists v: l = [v] \land a \right) \right)
///   \Rightarrow \text{is\_rightmost}(\text{from\_list}(l)) = \text{True}$
pub fn is_rightmost_on_empty_or_single_list_returns_true_test() {
  use list <- qcheck.given(list_of_empty_or_single_integer())
  let zipper = zlist.from_list(list)
  assert zlist.is_rightmost(zipper) == True
}

/// Is rightmost returns False on multi-element zipper.
/// For any list with at least two elements, the is_rightmost function should return False when at the beginning.
///
/// Formula: $\forall l: \text{List}, |l| \geq 2 \Rightarrow \text{is\_rightmost}(\text{from\_list}(l)) = \text{False}$
pub fn is_rightmost_on_multi_element_returns_false_test() {
  use list <- qcheck.given(list_of_at_least_two_integers())
  let zipper = zlist.from_list(list)
  assert zlist.is_rightmost(zipper) == False
}

//
// helper
//

fn list_of_empty_or_single_integer() {
  let list_length = qcheck.bounded_int(0, 1)
  let elements = qcheck.uniform_int()
  qcheck.generic_list(elements, list_length)
}

fn list_of_at_least_two_integers() {
  let list_length =
    qcheck.small_strictly_positive_int()
    |> qcheck.map(fn(i) { i + 1 })
  let elements = qcheck.uniform_int()
  qcheck.generic_list(elements, list_length)
}

fn non_empty_integer_list() {
  let list_length = qcheck.small_strictly_positive_int()
  let elements = qcheck.uniform_int()
  qcheck.generic_list(elements, list_length)
}

fn maybe_empty_integer_list() {
  let list_length = qcheck.small_non_negative_int()
  let elements = qcheck.uniform_int()
  qcheck.generic_list(elements, list_length)
}
