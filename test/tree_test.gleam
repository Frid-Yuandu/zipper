import gleam/option.{type Option, None, Some}
import zipper/tree

// For user-defined tree tests
type MyTree(a) {
  MyLeaf
  MyNode(a, MyTree(a), MyTree(a))
}

fn standard_to_my_tree(t: tree.Tree(a)) -> MyTree(a) {
  case t {
    tree.Leaf -> MyLeaf
    tree.Node(v, l, r) ->
      MyNode(v, standard_to_my_tree(l), standard_to_my_tree(r))
  }
}

fn my_tree_adapter() -> tree.Adapter(a, MyTree(a)) {
  let get_value = fn(t: MyTree(a)) -> Option(a) {
    case t {
      MyLeaf -> None
      MyNode(v, _, _) -> Some(v)
    }
  }

  let get_children = fn(t: MyTree(a)) -> #(Option(MyTree(a)), Option(MyTree(a))) {
    case t {
      MyLeaf -> #(None, None)
      MyNode(_, l, r) -> {
        let left = case l {
          MyLeaf -> None
          _ -> Some(l)
        }
        let right = case r {
          MyLeaf -> None
          _ -> Some(r)
        }
        #(left, right)
      }
    }
  }

  let build_node = fn(
    val: Option(a),
    children: #(Option(tree.Tree(a)), Option(tree.Tree(a))),
  ) -> MyTree(a) {
    case val {
      None -> MyLeaf
      Some(v) -> {
        let left = case children {
          #(Some(l), _) -> standard_to_my_tree(l)
          _ -> MyLeaf
        }
        let right = case children {
          #(_, Some(r)) -> standard_to_my_tree(r)
          _ -> MyLeaf
        }
        MyNode(v, left, right)
      }
    }
  }

  tree.Adapter(
    get_value: get_value,
    get_children: get_children,
    build_node: build_node,
  )
}

// Main module documentation example
pub fn doc_usage_example_test() {
  let my_tree =
    tree.Node(
      1,
      tree.Node(2, tree.Leaf, tree.Leaf),
      tree.Node(3, tree.Leaf, tree.Leaf),
    )

  let zipper = tree.from_standard_tree(my_tree)

  let assert Ok(zipper) = tree.go_left(zipper)
  let assert Ok(zipper) = tree.set_value(zipper, 4)
  let assert Ok(zipper) = tree.go_up(zipper)

  let final_tree = tree.to_standard_tree(zipper)
  assert final_tree
    == tree.Node(
      1,
      tree.Node(4, tree.Leaf, tree.Leaf),
      tree.Node(3, tree.Leaf, tree.Leaf),
    )
}

// from_standard_tree examples
pub fn doc_from_standard_tree_test() {
  let tree = tree.Node(1, tree.Leaf, tree.Leaf)
  let zipper = tree.from_standard_tree(tree)
  assert tree.get_value(zipper) == Ok(1)
}

// to_standard_tree examples
pub fn doc_to_standard_tree_test() {
  let t = tree.Node(1, tree.Leaf, tree.Leaf)
  let zipper = tree.from_standard_tree(t)
  assert tree.to_standard_tree(zipper) == t
}

// from_tree examples
pub fn doc_from_tree_test() {
  let my_tree = MyNode(1, MyNode(2, MyLeaf, MyLeaf), MyLeaf)
  let adapter = my_tree_adapter()
  let zipper = tree.from_tree(my_tree, adapter)
  assert tree.get_value(zipper) == Ok(1)
}

// to_tree examples
pub fn doc_to_tree_test() {
  let my_tree = MyNode(1, MyNode(2, MyLeaf, MyLeaf), MyLeaf)
  let adapter = my_tree_adapter()
  let zipper = tree.from_tree(my_tree, adapter)
  let converted_tree = tree.to_tree(zipper, adapter)
  assert converted_tree == my_tree
}

// get_value examples
pub fn doc_get_value_node_test() {
  let node_zipper = tree.from_standard_tree(tree.Node(42, tree.Leaf, tree.Leaf))
  assert tree.get_value(node_zipper) == Ok(42)
}

pub fn doc_get_value_leaf_test() {
  let leaf_zipper = tree.from_standard_tree(tree.Leaf)
  assert tree.get_value(leaf_zipper) == Error(Nil)
}

// get_standard_tree examples
pub fn doc_get_standard_tree_test() {
  let t = tree.Node(1, tree.Leaf, tree.Leaf)
  let zipper = tree.from_standard_tree(t)
  assert tree.get_standard_tree(zipper) == t
}

// get_tree examples
pub fn doc_get_tree_test() {
  let my_tree = MyNode(1, MyNode(2, MyLeaf, MyLeaf), MyLeaf)
  let adapter = my_tree_adapter()
  let zipper = tree.from_tree(my_tree, adapter)
  let assert Ok(zipper) = tree.go_left(zipper)
  let focused_subtree = tree.get_tree(zipper, adapter)
  assert focused_subtree == MyNode(2, MyLeaf, MyLeaf)
}

// set_value examples
pub fn doc_set_value_test() {
  let zipper = tree.from_standard_tree(tree.Node(1, tree.Leaf, tree.Leaf))
  let assert Ok(zipper) = tree.set_value(zipper, 42)
  assert tree.get_value(zipper) == Ok(42)
}

// set_standard_tree examples
pub fn doc_set_standard_tree_test() {
  let zipper = tree.from_standard_tree(tree.Node(1, tree.Leaf, tree.Leaf))
  let new_tree = tree.Node(2, tree.Leaf, tree.Leaf)
  let updated_zipper = tree.set_standard_tree(zipper, new_tree)
  assert tree.get_standard_tree(updated_zipper) == new_tree
}

// set_tree examples
pub fn doc_set_tree_test() {
  let zipper = tree.from_standard_tree(tree.Node(1, tree.Leaf, tree.Leaf))
  let my_subtree = MyNode(10, MyLeaf, MyLeaf)
  let adapter = my_tree_adapter()
  let updated_zipper = tree.set_tree(zipper, my_subtree, adapter)
  let final_tree = tree.to_tree(updated_zipper, adapter)
  assert final_tree == my_subtree
}

// update examples
pub fn doc_update_test() {
  let zipper = tree.from_standard_tree(tree.Node(1, tree.Leaf, tree.Leaf))
  let assert Ok(zipper) = tree.update(zipper, fn(x) { x * 2 })
  assert tree.get_value(zipper) == Ok(2)
}

// upsert examples
pub fn doc_upsert_test() {
  let zipper = tree.from_standard_tree(tree.Leaf)
  let updated_zipper =
    tree.upsert(zipper, fn(_) { tree.Node(1, tree.Leaf, tree.Leaf) })
  assert tree.get_value(updated_zipper) == Ok(1)
}

// set_left examples
pub fn doc_set_left_test() {
  let zipper = tree.from_standard_tree(tree.Node(1, tree.Leaf, tree.Leaf))
  let assert Ok(setted_zipper) =
    tree.set_left(zipper, tree.Node(2, tree.Leaf, tree.Leaf))
  assert tree.to_standard_tree(setted_zipper)
    == tree.Node(1, tree.Node(2, tree.Leaf, tree.Leaf), tree.Leaf)
}

// set_right examples
pub fn doc_set_right_test() {
  let zipper = tree.from_standard_tree(tree.Node(1, tree.Leaf, tree.Leaf))
  let assert Ok(setted_zipper) =
    tree.set_right(zipper, tree.Node(3, tree.Leaf, tree.Leaf))
  assert tree.to_standard_tree(setted_zipper)
    == tree.Node(1, tree.Leaf, tree.Node(3, tree.Leaf, tree.Leaf))
}

// delete examples
pub fn doc_delete_test() {
  let t = tree.Node(1, tree.Node(2, tree.Leaf, tree.Leaf), tree.Leaf)
  let zipper = tree.from_standard_tree(t)

  let assert Ok(zipper) = tree.go_left(zipper)
  let assert Ok(zipper) = tree.delete(zipper)

  assert tree.to_standard_tree(zipper) == tree.Node(1, tree.Leaf, tree.Leaf)
}

// delete_left examples
pub fn doc_delete_left_test() {
  let t = tree.Node(1, tree.Node(2, tree.Leaf, tree.Leaf), tree.Leaf)
  let zipper = tree.from_standard_tree(t)

  let assert Ok(deleted_zipper) = tree.delete_left(zipper)
  assert tree.to_standard_tree(deleted_zipper)
    == tree.Node(1, tree.Leaf, tree.Leaf)
}

// delete_right examples
pub fn doc_delete_right_test() {
  let t = tree.Node(1, tree.Leaf, tree.Node(3, tree.Leaf, tree.Leaf))
  let zipper = tree.from_standard_tree(t)

  let assert Ok(deleted_zipper) = tree.delete_right(zipper)
  assert tree.to_standard_tree(deleted_zipper)
    == tree.Node(1, tree.Leaf, tree.Leaf)
}

// is_root examples
pub fn doc_is_root_at_root_test() {
  let zipper =
    tree.from_standard_tree(tree.Node(
      1,
      tree.Node(2, tree.Leaf, tree.Leaf),
      tree.Leaf,
    ))
  assert tree.is_root(zipper) == True
}

pub fn doc_is_root_at_child_test() {
  let zipper =
    tree.from_standard_tree(tree.Node(
      1,
      tree.Node(2, tree.Leaf, tree.Leaf),
      tree.Leaf,
    ))
  let assert Ok(child_zipper) = tree.go_left(zipper)
  assert tree.is_root(child_zipper) == False
}

// go_left examples
pub fn doc_go_left_test() {
  let zipper =
    tree.from_standard_tree(tree.Node(
      1,
      tree.Node(2, tree.Leaf, tree.Leaf),
      tree.Leaf,
    ))
  let assert Ok(zipper) = tree.go_left(zipper)
  assert tree.get_value(zipper) == Ok(2)
}

// go_right examples
pub fn doc_go_right_test() {
  let zipper =
    tree.from_standard_tree(tree.Node(
      1,
      tree.Leaf,
      tree.Node(3, tree.Leaf, tree.Leaf),
    ))
  let assert Ok(zipper) = tree.go_right(zipper)
  assert tree.get_value(zipper) == Ok(3)
}

// go_up examples
pub fn doc_go_up_test() {
  let zipper =
    tree.from_standard_tree(tree.Node(
      1,
      tree.Node(2, tree.Leaf, tree.Leaf),
      tree.Leaf,
    ))
  let assert Ok(child_zipper) = tree.go_left(zipper)
  let assert Ok(parent_zipper) = tree.go_up(child_zipper)
  assert tree.get_value(parent_zipper) == Ok(1)
}
