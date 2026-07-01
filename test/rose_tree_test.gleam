import gleam/list
import helpers/generators
import qcheck
import zipper/rose_tree

// For user-defined tree tests
type MyRoseTree(a) {
  MyRoseTree(value: a, children: List(MyRoseTree(a)))
}

fn standard_to_my_rose_tree(t: rose_tree.RoseTree(a)) -> MyRoseTree(a) {
  MyRoseTree(
    value: t.value,
    children: list.map(t.children, standard_to_my_rose_tree),
  )
}

fn my_rose_tree_to_standard(t: MyRoseTree(a)) -> rose_tree.RoseTree(a) {
  rose_tree.RoseTree(
    value: t.value,
    children: list.map(t.children, my_rose_tree_to_standard),
  )
}

fn my_rose_tree_adapter() -> rose_tree.Adapter(a, MyRoseTree(a)) {
  let get_value = fn(t: MyRoseTree(a)) -> a { t.value }

  let get_children = fn(t: MyRoseTree(a)) -> List(rose_tree.RoseTree(a)) {
    list.map(t.children, my_rose_tree_to_standard)
  }

  let build_node = fn(val: a, children: List(rose_tree.RoseTree(a))) -> MyRoseTree(
    a,
  ) {
    MyRoseTree(
      value: val,
      children: list.map(children, standard_to_my_rose_tree),
    )
  }

  rose_tree.Adapter(
    get_value: get_value,
    get_children: get_children,
    build_node: build_node,
  )
}

// Main module documentation example
pub fn doc_usage_example_test() {
  let my_tree =
    rose_tree.RoseTree(1, [rose_tree.RoseTree(2, []), rose_tree.RoseTree(3, [])])

  let zipper = rose_tree.from_standard_tree(my_tree)

  let assert Ok(zipper) = rose_tree.go_down(zipper)
  let zipper = rose_tree.set_value(zipper, 4)
  let assert Ok(zipper) = rose_tree.go_up(zipper)

  let final_tree = rose_tree.to_standard_tree(zipper)
  assert final_tree
    == rose_tree.RoseTree(1, [
      rose_tree.RoseTree(4, []),
      rose_tree.RoseTree(3, []),
    ])
}

// from_standard_tree examples
pub fn doc_from_standard_tree_test() {
  let tree = rose_tree.RoseTree(1, [])
  let zipper = rose_tree.from_standard_tree(tree)
  assert rose_tree.get_value(zipper) == 1
}

// to_standard_tree examples
pub fn doc_to_standard_tree_test() {
  let tree = rose_tree.RoseTree(1, [rose_tree.RoseTree(2, [])])
  let zipper = rose_tree.from_standard_tree(tree)
  let assert Ok(zipper) = rose_tree.go_down(zipper)

  assert rose_tree.to_standard_tree(zipper) == tree
}

// from_tree examples
pub fn doc_from_tree_test() {
  let my_tree = MyRoseTree(1, [MyRoseTree(2, [])])
  let adapter = my_rose_tree_adapter()
  let zipper = rose_tree.from_tree(my_tree, adapter)
  assert rose_tree.get_value(zipper) == 1
}

// to_tree examples
pub fn doc_to_tree_test() {
  let my_tree = MyRoseTree(1, [MyRoseTree(2, [])])
  let adapter = my_rose_tree_adapter()
  let zipper = rose_tree.from_tree(my_tree, adapter)
  let converted_tree = rose_tree.to_tree(zipper, adapter)
  assert converted_tree == my_tree
}

// go_left examples
pub fn doc_go_left_test() {
  let tree =
    rose_tree.RoseTree(1, [rose_tree.RoseTree(2, []), rose_tree.RoseTree(3, [])])
  let zipper = rose_tree.from_standard_tree(tree)
  let assert Ok(zipper) = rose_tree.go_down(zipper)
  let assert Ok(zipper) = rose_tree.go_right(zipper)
  assert rose_tree.get_value(zipper) == 3

  let assert Ok(zipper) = rose_tree.go_left(zipper)
  assert rose_tree.get_value(zipper) == 2
}

// go_right examples
pub fn doc_go_right_test() {
  let tree =
    rose_tree.RoseTree(1, [rose_tree.RoseTree(2, []), rose_tree.RoseTree(3, [])])
  let zipper = rose_tree.from_standard_tree(tree)
  let assert Ok(zipper) = rose_tree.go_down(zipper)
  assert rose_tree.get_value(zipper) == 2
  let assert Ok(zipper) = rose_tree.go_right(zipper)
  assert rose_tree.get_value(zipper) == 3
}

// go_to_root examples
pub fn doc_go_to_root_test() {
  let tree =
    rose_tree.RoseTree(1, [
      rose_tree.RoseTree(2, [rose_tree.RoseTree(3, [])]),
    ])
  let zipper = rose_tree.from_standard_tree(tree)
  let assert Ok(child_zipper) = rose_tree.go_down(zipper)
  assert rose_tree.get_value(child_zipper) == 2

  let root_zipper = rose_tree.go_to_root(child_zipper)
  assert rose_tree.is_root(root_zipper) == True
  assert rose_tree.get_value(root_zipper) == 1
  assert rose_tree.to_standard_tree(root_zipper) == tree
}

// go_up examples
pub fn doc_go_up_test() {
  let tree = rose_tree.RoseTree(1, [rose_tree.RoseTree(2, [])])
  let zipper = rose_tree.from_standard_tree(tree)
  let assert Ok(zipper) = rose_tree.go_down(zipper)
  assert rose_tree.get_value(zipper) == 2

  let assert Ok(zipper) = rose_tree.go_up(zipper)
  assert rose_tree.get_value(zipper) == 1
}

// go_down examples
pub fn doc_go_down_test() {
  let tree = rose_tree.RoseTree(1, [rose_tree.RoseTree(2, [])])
  let zipper = rose_tree.from_standard_tree(tree)

  let assert Ok(zipper) = rose_tree.go_down(zipper)
  assert rose_tree.get_value(zipper) == 2
}

// get_value examples
pub fn doc_get_value_test() {
  let zipper = rose_tree.from_standard_tree(rose_tree.RoseTree(42, []))
  assert rose_tree.get_value(zipper) == 42
}

// get_standard_tree examples
pub fn doc_get_standard_tree_test() {
  let child_tree = rose_tree.RoseTree(2, [])
  let zipper = rose_tree.from_standard_tree(rose_tree.RoseTree(1, [child_tree]))
  let assert Ok(zipper) = rose_tree.go_down(zipper)

  assert rose_tree.get_standard_tree(zipper) == child_tree
}

// get_tree examples
pub fn doc_get_tree_test() {
  let my_child_tree = MyRoseTree(2, [])
  let my_tree = MyRoseTree(1, [my_child_tree])
  let adapter = my_rose_tree_adapter()
  let zipper = rose_tree.from_tree(my_tree, adapter)
  let assert Ok(zipper) = rose_tree.go_down(zipper)
  let focused_subtree = rose_tree.get_tree(zipper, adapter)
  assert focused_subtree == my_child_tree
}

// set_value examples
pub fn doc_set_value_test() {
  let zipper = rose_tree.from_standard_tree(rose_tree.RoseTree(1, []))
  let zipper = rose_tree.set_value(zipper, 42)
  assert rose_tree.get_value(zipper) == 42
}

// set_standard_tree examples
pub fn doc_set_standard_tree_test() {
  let zipper =
    rose_tree.from_standard_tree(
      rose_tree.RoseTree(1, [rose_tree.RoseTree(2, [])]),
    )
  let new_subtree = rose_tree.RoseTree(99, [])
  let zipper = rose_tree.set_standard_tree(zipper, new_subtree)

  assert rose_tree.to_standard_tree(zipper) == new_subtree
}

// set_tree examples
pub fn doc_set_tree_test() {
  let zipper =
    rose_tree.from_standard_tree(
      rose_tree.RoseTree(1, [rose_tree.RoseTree(2, [])]),
    )
  let my_subtree = MyRoseTree(99, [])
  let adapter = my_rose_tree_adapter()
  let updated_zipper = rose_tree.set_tree(zipper, my_subtree, adapter)

  assert rose_tree.get_tree(updated_zipper, adapter) == my_subtree
}

// update examples
pub fn doc_update_test() {
  let zipper = rose_tree.from_standard_tree(rose_tree.RoseTree(10, []))
  let zipper = rose_tree.update(zipper, fn(x) { x * 2 })
  assert rose_tree.get_value(zipper) == 20
}

// map_focus examples
pub fn doc_map_focus_test() {
  let zipper = rose_tree.from_standard_tree(rose_tree.RoseTree(10, []))
  let zipper =
    rose_tree.map_focus(zipper, fn(t) {
      rose_tree.RoseTree(..t, children: [
        rose_tree.RoseTree(value: 1, children: []),
        rose_tree.RoseTree(value: 2, children: []),
        rose_tree.RoseTree(value: 3, children: []),
      ])
    })
  let assert Ok(zipper) = rose_tree.go_down(zipper)

  assert rose_tree.get_value(zipper) == 1
}

// insert_left examples
pub fn doc_insert_left_test() {
  let tree = rose_tree.RoseTree(0, [rose_tree.RoseTree(2, [])])
  let assert Ok(zipper) =
    rose_tree.from_standard_tree(tree) |> rose_tree.go_down
  let new_sibling = rose_tree.RoseTree(1, [])
  let assert Ok(zipper) = rose_tree.insert_left(zipper, new_sibling)

  assert rose_tree.to_standard_tree(zipper)
    == rose_tree.RoseTree(0, [
      rose_tree.RoseTree(1, []),
      rose_tree.RoseTree(2, []),
    ])
}

// insert_right examples
pub fn doc_insert_right_test() {
  let tree = rose_tree.RoseTree(0, [rose_tree.RoseTree(1, [])])
  let assert Ok(zipper) =
    rose_tree.from_standard_tree(tree) |> rose_tree.go_down
  let new_sibling = rose_tree.RoseTree(2, [])
  let assert Ok(zipper) = rose_tree.insert_right(zipper, new_sibling)

  assert rose_tree.to_standard_tree(zipper)
    == rose_tree.RoseTree(0, [
      rose_tree.RoseTree(1, []),
      rose_tree.RoseTree(2, []),
    ])
}

// insert_child examples
pub fn doc_insert_child_test() {
  let zipper =
    rose_tree.from_standard_tree(
      rose_tree.RoseTree(1, [rose_tree.RoseTree(3, [])]),
    )
  let zipper = rose_tree.insert_child(zipper, rose_tree.RoseTree(2, []))

  assert rose_tree.to_standard_tree(zipper)
    == rose_tree.RoseTree(1, [
      rose_tree.RoseTree(2, []),
      rose_tree.RoseTree(3, []),
    ])
}

// insert_child_back examples
pub fn doc_insert_child_back_test() {
  let zipper =
    rose_tree.from_standard_tree(
      rose_tree.RoseTree(1, [rose_tree.RoseTree(2, [])]),
    )
  let zipper = rose_tree.insert_child_back(zipper, rose_tree.RoseTree(3, []))

  assert rose_tree.to_standard_tree(zipper)
    == rose_tree.RoseTree(1, [
      rose_tree.RoseTree(2, []),
      rose_tree.RoseTree(3, []),
    ])
}

// delete examples
pub fn doc_delete_test() {
  let tree =
    rose_tree.RoseTree(0, [
      rose_tree.RoseTree(1, []),
      rose_tree.RoseTree(2, []),
      rose_tree.RoseTree(3, []),
    ])
  let zipper = rose_tree.from_standard_tree(tree)
  let assert Ok(zipper) = rose_tree.go_down(zipper)
  let assert Ok(zipper) = rose_tree.go_right(zipper)

  let assert Ok(zipper) = rose_tree.delete(zipper)
  assert rose_tree.get_value(zipper) == 3

  assert rose_tree.to_standard_tree(zipper)
    == rose_tree.RoseTree(0, [
      rose_tree.RoseTree(1, []),
      rose_tree.RoseTree(3, []),
    ])
}

// is_root examples
pub fn doc_is_root_test() {
  let zipper =
    rose_tree.from_standard_tree(
      rose_tree.RoseTree(1, [rose_tree.RoseTree(2, [])]),
    )
  assert rose_tree.is_root(zipper) == True

  let assert Ok(child_zipper) = rose_tree.go_down(zipper)
  assert rose_tree.is_root(child_zipper) == False
}

// is_leaf examples
pub fn doc_is_leaf_test() {
  let leaf_zipper = rose_tree.from_standard_tree(rose_tree.RoseTree(1, []))
  assert rose_tree.is_leaf(leaf_zipper) == True

  let node_zipper =
    rose_tree.from_standard_tree(
      rose_tree.RoseTree(1, [rose_tree.RoseTree(2, [])]),
    )
  assert rose_tree.is_leaf(node_zipper) == False
}

// is_leftmost examples
pub fn doc_is_leftmost_test() {
  let tree =
    rose_tree.RoseTree(0, [rose_tree.RoseTree(1, []), rose_tree.RoseTree(2, [])])
  let zipper = rose_tree.from_standard_tree(tree)
  let assert Ok(zipper) = rose_tree.go_down(zipper)

  assert rose_tree.is_leftmost(zipper) == True
}

// is_rightmost examples
pub fn doc_is_rightmost_test() {
  let tree =
    rose_tree.RoseTree(0, [rose_tree.RoseTree(1, []), rose_tree.RoseTree(2, [])])
  let zipper = rose_tree.from_standard_tree(tree)
  let assert Ok(zipper) = rose_tree.go_down(zipper)
  let assert Ok(zipper) = rose_tree.go_right(zipper)

  assert rose_tree.is_rightmost(zipper) == True
}

// --- map_focus property-based tests ---

/// Identity: applying identity function changes nothing.
///
/// Formula: $\forall t: \text{RoseTree} \Rightarrow \text{to\_standard\_tree}(\text{map\_focus}(\text{from\_standard\_tree}(t), \text{id})) = t$
pub fn map_focus_identity_test() {
  use tree <- qcheck.given(gen_rose_tree())
  let zipper = rose_tree.from_standard_tree(tree)
  let mapped = rose_tree.map_focus(zipper, fn(t) { t })

  assert rose_tree.to_standard_tree(mapped) == tree
}

/// Composition: sequential map_focus equals composed transform.
///
/// Formula: $\forall t, f, g \Rightarrow \text{map\_focus}(\text{map\_focus}(z, f), g) = \text{map\_focus}(z, g \circ f)$
pub fn map_focus_composition_test() {
  use tree <- qcheck.given(gen_rose_tree())
  let zipper = rose_tree.from_standard_tree(tree)

  let f = fn(t: rose_tree.RoseTree(Int)) {
    rose_tree.RoseTree(..t, value: t.value * 2)
  }
  let g = fn(t: rose_tree.RoseTree(Int)) {
    rose_tree.RoseTree(..t, children: [rose_tree.RoseTree(0, []), ..t.children])
  }

  let way1 = rose_tree.map_focus(rose_tree.map_focus(zipper, f), g)
  let way2 = rose_tree.map_focus(zipper, fn(t) { g(f(t)) })

  assert rose_tree.to_standard_tree(way1) == rose_tree.to_standard_tree(way2)
}

/// Focus equivalence: the value of the mapped focus equals the transform applied to the original focus.
///
/// Formula: $\forall t, f \Rightarrow \text{get\_value}(\text{map\_focus}(z, f)) = f(\text{get\_standard\_tree}(z)).\text{value}$
pub fn map_focus_focus_equivalence_test() {
  use tree <- qcheck.given(gen_rose_tree())
  let zipper = rose_tree.from_standard_tree(tree)
  let f = fn(t: rose_tree.RoseTree(Int)) {
    rose_tree.RoseTree(..t, value: t.value + 1)
  }

  let mapped = rose_tree.map_focus(zipper, f)

  assert rose_tree.get_value(mapped) == f(tree).value
}

/// Navigation preservation: map_focus does not affect navigation state.
///
/// Formula: $\forall t, f \Rightarrow \text{is\_leftmost}(z) = \text{is\_leftmost}(\text{map\_focus}(z, f))$
pub fn map_focus_navigation_preservation_test() {
  use tree <- qcheck.given(gen_rose_tree())
  let zipper = rose_tree.from_standard_tree(tree)
  let f = fn(t: rose_tree.RoseTree(Int)) {
    rose_tree.RoseTree(..t, value: t.value + 1)
  }

  let mapped = rose_tree.map_focus(zipper, f)

  assert rose_tree.is_leftmost(zipper) == rose_tree.is_leftmost(mapped)
  assert rose_tree.is_rightmost(zipper) == rose_tree.is_rightmost(mapped)
}

/// Round-trip: map_focus is equivalent to get → transform → set.
///
/// Formula: $\forall t, f \Rightarrow \text{map\_focus}(z, f) = \text{set\_standard\_tree}(z, f(\text{get\_standard\_tree}(z)))$
pub fn map_focus_round_trip_test() {
  use tree <- qcheck.given(gen_rose_tree())
  let zipper = rose_tree.from_standard_tree(tree)
  let f = fn(t: rose_tree.RoseTree(Int)) {
    rose_tree.RoseTree(..t, value: t.value * 2)
  }

  let way1 = rose_tree.map_focus(zipper, f)
  let way2 =
    rose_tree.set_standard_tree(zipper, f(rose_tree.get_standard_tree(zipper)))

  assert rose_tree.to_standard_tree(way1) == rose_tree.to_standard_tree(way2)
}

//
// generators
//

/// Generates a rose tree of arbitrary shape and size.
///
/// Uses a depth-biased recursive construction.  The maximum depth is fixed
/// and small, and each node has at most three children, so generated trees
/// stay small and shrinking remains fast.
fn gen_rose_tree() {
  let generator = {
    use self, size <- generators.fixpoint()
    case size {
      0 ->
        qcheck.map(qcheck.small_non_negative_int(), rose_tree.RoseTree(_, []))
      n -> {
        use value <- qcheck.bind(qcheck.small_non_negative_int())
        use children <- qcheck.map(qcheck.generic_list(
          self(n / 2),
          qcheck.bounded_int(0, 3),
        ))
        rose_tree.RoseTree(value, children)
      }
    }
  }

  qcheck.sized_from(generator, qcheck.small_non_negative_int())
}
