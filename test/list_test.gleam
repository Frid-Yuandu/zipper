import gleam/option.{type Option, None, Some}
import gleam/result
import gleeunit/should
import qcheck
import zipper/list

// Main module documentation example
pub fn doc_example_comprehensive_operations_test() {
  let z = list.from_list([1, 2, 3, 4])

  let assert Ok(new_z) =
    z
    |> list.go_right()
    |> result.try(list.set(_, 99))
    |> result.map(list.insert_left(_, 42))
    |> result.try(list.go_right)
    |> result.try(list.delete)

  assert new_z |> list.to_list == [1, 42, 99, 4]
}

// from_list examples
pub fn doc_example_from_list_get_first_element_test() {
  let z = list.from_list([1, 2, 3])
  assert list.get(z) == Ok(1)
}

pub fn doc_example_from_list_to_list_test() {
  let z = list.from_list([1, 2, 3])
  assert list.to_list(z) == [1, 2, 3]
}

// new() examples
pub fn doc_example_new_empty_list_test() {
  let z = list.new()
  assert list.to_list(z) == []
}

// get() examples
pub fn doc_example_get_from_non_empty_test() {
  let z = list.from_list([1, 2, 3])
  assert list.get(z) == Ok(1)
}

pub fn doc_example_get_from_empty_test() {
  let z = list.new()
  assert list.get(z) == Error(Nil)
}

// insert_left() examples
pub fn doc_example_insert_left_non_empty_test() {
  let z =
    list.from_list([2, 3])
    |> list.insert_left(1)
  assert list.to_list(z) == [1, 2, 3]
}

pub fn doc_example_insert_left_preserves_focus_test() {
  let z =
    list.from_list([2, 3])
    |> list.insert_left(1)
  assert list.get(z) == Ok(2)
}

pub fn doc_example_insert_left_into_empty_test() {
  let z =
    list.new()
    |> list.insert_left(42)
  assert list.get(z) == Ok(42)
}

// insert_right() examples
pub fn doc_example_insert_right_test() {
  let z =
    list.from_list([1, 2])
    |> list.insert_right(3)
  assert list.to_list(z) == [1, 3, 2]
}

// set() examples
pub fn doc_example_set_value_test() {
  let z = list.from_list([1, 2, 3])
  let assert Ok(new_z) = list.set(z, 99)
  assert list.to_list(new_z) == [99, 2, 3]
}

// update() examples
pub fn doc_example_update_value_test() {
  let z = list.from_list([1, 2, 3])
  let assert Ok(new_z) = list.update(z, fn(x) { x * 2 })
  assert list.to_list(new_z) == [2, 2, 3]
}

// upsert() examples
pub fn doc_example_upsert_update_existing_test() {
  let z = list.from_list([1, 2, 3])
  let new_z =
    list.upsert(z, fn(x: Option(Int)) {
      case x {
        Some(old) -> 2 * old
        None -> 42
      }
    })
  assert list.to_list(new_z) == [2, 2, 3]
}

pub fn doc_example_upsert_insert_when_empty_test() {
  let z = list.new()
  let new_z =
    list.upsert(z, fn(x: Option(Int)) {
      case x {
        Some(old) -> 2 * old
        None -> 42
      }
    })
  assert list.to_list(new_z) == [42]
}

// delete() examples
pub fn doc_example_delete_element_test() {
  let z = list.from_list([1, 2, 3])
  let assert Ok(new_z) = list.delete(z)
  assert list.to_list(new_z) == [2, 3]
}

// is_empty() examples
pub fn doc_example_is_empty_new_test() {
  let z = list.new()
  assert list.is_empty(z) == True
}

pub fn doc_example_is_empty_with_elements_test() {
  let z = list.from_list([1])
  assert list.is_empty(z) == False
}

// is_leftmost() examples
pub fn doc_example_is_leftmost_beginning_test() {
  let z = list.from_list([1, 2, 3])
  assert list.is_leftmost(z) == True
}

pub fn doc_example_is_leftmost_after_moving_right_test() {
  let z = list.from_list([1, 2, 3])
  let assert Ok(moved_z) = list.go_right(z)
  assert list.is_leftmost(moved_z) == False
}

// is_rightmost() examples
pub fn doc_example_is_rightmost_end_test() {
  let z = list.from_list([1, 2, 3])
  let assert Ok(z1) = list.go_right(z)
  let assert Ok(z2) = list.go_right(z1)
  assert list.is_rightmost(z2) == True
}

pub fn doc_example_is_rightmost_beginning_test() {
  let z = list.from_list([1, 2, 3])
  assert list.is_rightmost(z) == False
}

// go_left() examples
pub fn doc_example_go_left_and_back_test() {
  let z = list.from_list([1, 2, 3])
  let assert Ok(right_z) = list.go_right(z)
  let assert Ok(left_z) = list.go_left(right_z)
  assert list.get(left_z) == Ok(1)
}

// go_right() examples
pub fn doc_example_go_right_test() {
  let z = list.from_list([1, 2, 3])
  let assert Ok(right_z) = list.go_right(z)
  assert list.get(right_z) == Ok(2)
}

//
// property-based testing
//

pub fn round_trip_conversion_invariant__test() {
  let list_length = qcheck.small_non_negative_int()
  let elements = qcheck.uniform_int()
  use list <- qcheck.given(qcheck.generic_list(elements, list_length))
  let new_list = list.from_list(list) |> list.to_list()
  assert list == new_list
}

pub fn right_navigation_invertibility_on_intermediate_elements__test() {
  let list_length = qcheck.small_strictly_positive_int()
  let elements = qcheck.uniform_int()
  // generate a non-empty list avoiding insertion changes the focus
  use list <- qcheck.given(qcheck.generic_list(elements, list_length))
  use inserted_value <- qcheck.given(qcheck.uniform_int())
  let zipper = list.from_list(list) |> list.insert_right(inserted_value)
  let assert Ok(navigated_zipper) =
    zipper |> list.go_right() |> result.try(list.go_left)
  assert navigated_zipper == zipper
}

pub fn left_navigation_invertibility_on_intermediate_elements__test() {
  let list_length = qcheck.small_strictly_positive_int()
  let elements = qcheck.uniform_int()
  // generate a non-empty list avoiding insertion changes the focus
  use list <- qcheck.given(qcheck.generic_list(elements, list_length))
  use inserted_value <- qcheck.given(qcheck.uniform_int())
  let zipper = list.from_list(list) |> list.insert_left(inserted_value)
  let assert Ok(navigated_zipper) =
    zipper |> list.go_left() |> result.try(list.go_right)
  assert navigated_zipper == zipper
}

pub fn right_navigation_erroneous_on_rightmost_elements__test() {
  let list_length = qcheck.small_non_negative_int()
  let elements = qcheck.uniform_int()
  use list <- qcheck.given(qcheck.generic_list(elements, list_length))

  let rightmost_zipper = list.from_list(list) |> go_to_the_rightmost
  should.be_error(list.go_right(rightmost_zipper))
}

fn go_to_the_rightmost(zipper: list.Zipper(a)) -> list.Zipper(a) {
  case list.is_rightmost(zipper) {
    True -> zipper
    False -> {
      let assert Ok(zipper) = list.go_right(zipper)
      go_to_the_rightmost(zipper)
    }
  }
}

pub fn left_navigation_erroneous_on_leftmost_elements__test() {
  let list_length = qcheck.small_non_negative_int()
  let elements = qcheck.uniform_int()
  use list <- qcheck.given(qcheck.generic_list(elements, list_length))
  let zipper = list.from_list(list)
  should.be_error(list.go_left(zipper))
}
