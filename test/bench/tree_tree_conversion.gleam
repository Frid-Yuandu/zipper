import gleam/io
import gleam/option.{type Option, None, Some}
import gleamy/bench
import zipper/tree

type MyTree(a) {
  MyLeaf
  MyNode(a, MyTree(a), MyTree(a))
}

fn my_tree_adapter() -> tree.Adapter(Int, MyTree(Int)) {
  let get_value = fn(t: MyTree(Int)) -> Option(Int) {
    case t {
      MyLeaf -> None
      MyNode(v, _, _) -> Some(v)
    }
  }

  let get_children = fn(t: MyTree(Int)) -> #(
    Option(MyTree(Int)),
    Option(MyTree(Int)),
  ) {
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
    val: Option(Int),
    children: #(Option(MyTree(Int)), Option(MyTree(Int))),
  ) -> MyTree(Int) {
    case val {
      None -> MyLeaf
      Some(v) -> {
        let left = case children {
          #(Some(l), _) -> l
          _ -> MyLeaf
        }
        let right = case children {
          #(_, Some(r)) -> r
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

// Tail-recursive balanced binary tree builder (iterative with stack).
//
// Frames mirror the `standard_tree_to_user_tree` pattern:
//   Fresh(depth)  – subtree not yet visited
//   Ready(depth, is_left_present, is_right_present) – children consumed
fn build_balanced_tree(depth: Int) -> tree.Tree(Int) {
  build_balanced_iter([BalFresh(depth)], [])
}

type BalFrame {
  BalFresh(Int)
  BalReady(depth: Int, left_done: Bool, right_done: Bool)
}

fn build_balanced_iter(
  stack: List(BalFrame),
  result: List(tree.Tree(Int)),
) -> tree.Tree(Int) {
  case stack {
    [] -> {
      let assert [t] = result
      t
    }

    [BalFresh(d), ..rest] -> {
      case d {
        0 -> build_balanced_iter(rest, [tree.Leaf, ..result])
        _ -> {
          let frame = BalReady(d, True, True)
          let stack = [BalFresh(d - 1), BalFresh(d - 1), frame, ..rest]
          build_balanced_iter(stack, result)
        }
      }
    }

    [BalReady(d, True, True), ..stack] -> {
      let assert [right, left, ..remaining] = result
      let node = tree.Node(d, left, right)
      build_balanced_iter(stack, [node, ..remaining])
    }

    [BalReady(_, _, _), ..] -> panic as "unreachable"
  }
}

fn build_left_skewed_tree(depth: Int) -> tree.Tree(Int) {
  build_left_skewed_iter([BalFresh(depth)], [])
}

fn build_left_skewed_iter(
  stack: List(BalFrame),
  result: List(tree.Tree(Int)),
) -> tree.Tree(Int) {
  case stack {
    [] -> {
      let assert [t] = result
      t
    }

    [BalFresh(d), ..rest] -> {
      case d {
        0 -> build_left_skewed_iter(rest, [tree.Leaf, ..result])
        _ -> {
          let frame = BalReady(d, True, False)
          let stack = [BalFresh(d - 1), frame, ..rest]
          build_left_skewed_iter(stack, result)
        }
      }
    }

    [BalReady(d, True, False), ..stack] -> {
      let assert [left, ..remaining] = result
      let node = tree.Node(d, left, tree.Leaf)
      build_left_skewed_iter(stack, [node, ..remaining])
    }

    [BalReady(_, _, _), ..] -> panic as "unreachable"
  }
}

fn build_right_skewed_tree(depth: Int) -> tree.Tree(Int) {
  build_right_skewed_iter([BalFresh(depth)], [])
}

fn build_right_skewed_iter(
  stack: List(BalFrame),
  result: List(tree.Tree(Int)),
) -> tree.Tree(Int) {
  case stack {
    [] -> {
      let assert [t] = result
      t
    }

    [BalFresh(d), ..rest] -> {
      case d {
        0 -> build_right_skewed_iter(rest, [tree.Leaf, ..result])
        _ -> {
          let frame = BalReady(d, False, True)
          let stack = [BalFresh(d - 1), frame, ..rest]
          build_right_skewed_iter(stack, result)
        }
      }
    }

    [BalReady(d, False, True), ..stack] -> {
      let assert [right, ..remaining] = result
      let node = tree.Node(d, tree.Leaf, right)
      build_right_skewed_iter(stack, [node, ..remaining])
    }

    [BalReady(_, _, _), ..] -> panic as "unreachable"
  }
}

// Tail-recursive conversion from standard tree to user tree.
//
// Frames mirror the `standard_tree_to_user_tree_iter` pattern.
type MyTreeFrame {
  MTFresh(tree.Tree(Int))
  MTReady(Option(Int), left_done: Bool, right_done: Bool)
}

fn to_my_tree(t: tree.Tree(Int)) -> MyTree(Int) {
  to_my_tree_iter([MTFresh(t)], [])
}

fn to_my_tree_iter(
  stack: List(MyTreeFrame),
  result: List(MyTree(Int)),
) -> MyTree(Int) {
  case stack {
    [] -> {
      let assert [t] = result
      t
    }

    [MTFresh(tree.Leaf), ..rest] -> {
      to_my_tree_iter(rest, [MyLeaf, ..result])
    }

    [MTFresh(tree.Node(v, l, r)), ..rest] ->
      case l, r {
        tree.Leaf, tree.Leaf -> {
          let frame = MTReady(Some(v), False, False)
          to_my_tree_iter([frame, ..rest], result)
        }
        tree.Leaf, tree.Node(..) as r -> {
          let frame = MTReady(Some(v), False, True)
          let stack = [MTFresh(r), frame, ..rest]
          to_my_tree_iter(stack, result)
        }
        tree.Node(..) as l, tree.Leaf -> {
          let frame = MTReady(Some(v), True, False)
          let stack = [MTFresh(l), frame, ..rest]
          to_my_tree_iter(stack, result)
        }
        tree.Node(..) as l, tree.Node(..) as r -> {
          let frame = MTReady(Some(v), True, True)
          let stack = [MTFresh(l), MTFresh(r), frame, ..rest]
          to_my_tree_iter(stack, result)
        }
      }

    [MTReady(val, left_done:, right_done:), ..stack] -> {
      case left_done, right_done {
        False, False -> {
          let node = case val {
            None -> MyLeaf
            Some(v) -> MyNode(v, MyLeaf, MyLeaf)
          }
          to_my_tree_iter(stack, [node, ..result])
        }
        False, True -> {
          let assert [right, ..remaining] = result
          let node = case val {
            None -> MyLeaf
            Some(v) -> MyNode(v, MyLeaf, right)
          }
          to_my_tree_iter(stack, [node, ..remaining])
        }
        True, False -> {
          let assert [left, ..remaining] = result
          let node = case val {
            None -> MyLeaf
            Some(v) -> MyNode(v, left, MyLeaf)
          }
          to_my_tree_iter(stack, [node, ..remaining])
        }
        True, True -> {
          let assert [right, left, ..remaining] = result
          let node = case val {
            None -> MyLeaf
            Some(v) -> MyNode(v, left, right)
          }
          to_my_tree_iter(stack, [node, ..remaining])
        }
      }
    }
  }
}

fn go_deepest_left(zipper: tree.Zipper(Int)) -> tree.Zipper(Int) {
  case tree.go_left(zipper) {
    Ok(z) -> go_deepest_left(z)
    Error(_) -> zipper
  }
}

fn go_deepest_right(zipper: tree.Zipper(Int)) -> tree.Zipper(Int) {
  case tree.go_right(zipper) {
    Ok(z) -> go_deepest_right(z)
    Error(_) -> zipper
  }
}

pub fn main() {
  let balanced_7 = build_balanced_tree(7)
  let balanced_12 = build_balanced_tree(12)
  let balanced_17 = build_balanced_tree(17)
  let left_10 = build_left_skewed_tree(10)
  let left_1000 = build_left_skewed_tree(1000)
  let left_100000 = build_left_skewed_tree(100_000)
  let right_10 = build_right_skewed_tree(10)

  let my_tree_7 = to_my_tree(balanced_7)
  let my_tree_12 = to_my_tree(balanced_12)
  let my_tree_17 = to_my_tree(balanced_17)
  let my_left_10 = to_my_tree(left_10)
  let my_left_1000 = to_my_tree(left_1000)
  let my_left_100000 = to_my_tree(left_100000)
  let my_right_10 = to_my_tree(right_10)

  io.println("=== Binary Tree Conversion Benchmarks ===\n")

  io.println("--- from_standard_tree (Tree -> Zipper) ---")
  bench.run(
    [
      bench.Input("balanced depth=17", balanced_17),
      bench.Input("left-skewed depth=100000", left_100000),
      bench.Input("right-skewed depth=10", right_10),
    ],
    [bench.Function("from_standard_tree", tree.from_standard_tree)],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.SD, bench.P(99)])
  |> io.println()

  io.println(
    "\n--- to_standard_tree (Zipper -> Tree, focus at deepest node) ---",
  )
  let deepest_17 = balanced_17 |> tree.from_standard_tree |> go_deepest_left
  let deepest_left_10 = left_10 |> tree.from_standard_tree |> go_deepest_left
  let deepest_left_1000 =
    left_1000 |> tree.from_standard_tree |> go_deepest_left
  let deepest_left_100000 =
    left_100000 |> tree.from_standard_tree |> go_deepest_left
  let deepest_right_10 = right_10 |> tree.from_standard_tree |> go_deepest_right

  bench.run(
    [
      bench.Input("balanced depth=17 (d=17)", deepest_17),
      bench.Input("left-skewed depth=10 (d=10)", deepest_left_10),
      bench.Input("left-skewed depth=1000 (d=1000)", deepest_left_1000),
      bench.Input("left-skewed depth=100000 (d=100000)", deepest_left_100000),
      bench.Input("right-skewed depth=10 (d=10)", deepest_right_10),
    ],
    [bench.Function("to_standard_tree", tree.to_standard_tree)],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.SD, bench.P(99)])
  |> io.println()

  io.println("\n--- from_tree (UserTree -> Zipper via adapter) ---")
  let adapter = my_tree_adapter()

  bench.run(
    [
      bench.Input("balanced depth=7", #(my_tree_7, adapter)),
      bench.Input("balanced depth=12", #(my_tree_12, adapter)),
      bench.Input("balanced depth=17", #(my_tree_17, adapter)),
      bench.Input("left-skewed depth=10", #(my_left_10, adapter)),
      bench.Input("left-skewed depth=1000", #(my_left_1000, adapter)),
      bench.Input("left-skewed depth=100000", #(my_left_100000, adapter)),
      bench.Input("right-skewed depth=10", #(my_right_10, adapter)),
    ],
    [
      bench.Function("from_tree", fn(input) {
        let #(t, a) = input
        tree.from_tree(t, a)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.SD, bench.P(99)])
  |> io.println()

  io.println("\n--- to_tree (Zipper -> UserTree via adapter) ---")
  let zippered_7 = tree.from_standard_tree(balanced_7)
  let zippered_12 = tree.from_standard_tree(balanced_12)
  let zippered_17 = tree.from_standard_tree(balanced_17)
  let zippered_left_10 = tree.from_standard_tree(left_10)
  let zippered_left_1000 = tree.from_standard_tree(left_1000)
  let zippered_left_100000 = tree.from_standard_tree(left_100000)
  let zippered_right_10 = tree.from_standard_tree(right_10)

  bench.run(
    [
      bench.Input("balanced depth=7", #(zippered_7, adapter)),
      bench.Input("balanced depth=12", #(zippered_12, adapter)),
      bench.Input("balanced depth=17", #(zippered_17, adapter)),
      bench.Input("left-skewed depth=10", #(zippered_left_10, adapter)),
      bench.Input("left-skewed depth=1000", #(zippered_left_1000, adapter)),
      bench.Input("left-skewed depth=100000", #(zippered_left_100000, adapter)),
      bench.Input("right-skewed depth=10", #(zippered_right_10, adapter)),
    ],
    [
      bench.Function("to_tree", fn(input) {
        let #(z, a) = input
        tree.to_tree(z, a)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.SD, bench.P(99)])
  |> io.println()
}
