import gleam/list
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
