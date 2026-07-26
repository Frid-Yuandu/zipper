import gleam/io
import gleam/list
import gleamy/bench
import zipper/rose_tree

type MyRoseTree(a) {
  MyRoseTree(value: a, children: List(MyRoseTree(a)))
}

fn my_rose_tree_adapter() -> rose_tree.Adapter(Int, MyRoseTree(Int)) {
  let get_value = fn(t: MyRoseTree(Int)) -> Int { t.value }

  let get_children = fn(t: MyRoseTree(Int)) -> List(MyRoseTree(Int)) {
    t.children
  }

  let build_node = fn(val: Int, children: List(MyRoseTree(Int))) -> MyRoseTree(
    Int,
  ) {
    MyRoseTree(value: val, children:)
  }

  rose_tree.Adapter(
    get_value: get_value,
    get_children: get_children,
    build_node: build_node,
  )
}

// Tail-recursive balanced rose tree builder (iterative with stack).
//
// Frames mirror the `standard_tree_to_user_tree_iter` pattern:
//   Fresh(depth)               – subtree not yet visited
//   Ready(value, child_count)  – children consumed, ready to assemble
type RoseFrame {
  RoseFresh(depth: Int)
  RoseReady(value: Int, child_count: Int)
}

fn build_balanced_rose_tree(depth: Int, width: Int) -> rose_tree.RoseTree(Int) {
  build_balanced_rose_iter([RoseFresh(depth)], [], width)
}

fn build_balanced_rose_iter(
  stack: List(RoseFrame),
  result: List(rose_tree.RoseTree(Int)),
  width: Int,
) -> rose_tree.RoseTree(Int) {
  case stack {
    [] -> {
      let assert [t] = result
      t
    }

    [RoseFresh(d), ..rest] -> {
      case d {
        0 -> {
          let node = rose_tree.RoseTree(0, [])
          build_balanced_rose_iter(rest, [node, ..result], width)
        }
        _ -> {
          let child_frames =
            list.range(1, width) |> list.map(fn(_) { RoseFresh(d - 1) })
          let frame = RoseReady(d, width)
          let stack = list.append(child_frames, [frame, ..rest])
          build_balanced_rose_iter(stack, result, width)
        }
      }
    }

    [RoseReady(value, child_count), ..stack] -> {
      let #(children, remaining) = list.split(result, child_count)
      let node = rose_tree.RoseTree(value, list.reverse(children))
      build_balanced_rose_iter(stack, [node, ..remaining], width)
    }
  }
}

fn build_linear_rose_tree(depth: Int) -> rose_tree.RoseTree(Int) {
  build_linear_rose_iter([RoseFresh(depth)], [])
}

fn build_linear_rose_iter(
  stack: List(RoseFrame),
  result: List(rose_tree.RoseTree(Int)),
) -> rose_tree.RoseTree(Int) {
  case stack {
    [] -> {
      let assert [t] = result
      t
    }

    [RoseFresh(d), ..rest] -> {
      case d {
        0 -> {
          let node = rose_tree.RoseTree(0, [])
          build_linear_rose_iter(rest, [node, ..result])
        }
        _ -> {
          let frame = RoseReady(d, 1)
          let stack = [RoseFresh(d - 1), frame, ..rest]
          build_linear_rose_iter(stack, result)
        }
      }
    }

    [RoseReady(value, 1), ..stack] -> {
      let assert [child, ..remaining] = result
      let node = rose_tree.RoseTree(value, [child])
      build_linear_rose_iter(stack, [node, ..remaining])
    }

    [RoseReady(_, _), ..] -> panic as "unreachable"
  }
}

fn build_wide_rose_tree(width: Int) -> rose_tree.RoseTree(Int) {
  let children =
    list.range(1, width)
    |> list.map(fn(i) { rose_tree.RoseTree(i, []) })
  rose_tree.RoseTree(0, children)
}

// Tail-recursive conversion from standard rose tree to user rose tree.
//
// Frames mirror the `standard_tree_to_user_tree_iter` pattern.
type MyRoseFrame {
  MRFresh(rose_tree.RoseTree(Int))
  MRReady(value: Int, child_count: Int)
}

fn to_my_rose_tree(t: rose_tree.RoseTree(Int)) -> MyRoseTree(Int) {
  to_my_rose_tree_iter([MRFresh(t)], [])
}

fn to_my_rose_tree_iter(
  stack: List(MyRoseFrame),
  result: List(MyRoseTree(Int)),
) -> MyRoseTree(Int) {
  case stack {
    [] -> {
      let assert [t] = result
      t
    }

    [MRFresh(rose_tree.RoseTree(value:, children:)), ..rest] -> {
      let child_count = list.length(children)
      let frame = MRReady(value:, child_count:)
      let child_frames = list.map(children, MRFresh)
      let stack = list.append(child_frames, [frame, ..rest])
      to_my_rose_tree_iter(stack, result)
    }

    [MRReady(value, child_count), ..stack] -> {
      let #(children, remaining) = list.split(result, child_count)
      let node = MyRoseTree(value, list.reverse(children))
      to_my_rose_tree_iter(stack, [node, ..remaining])
    }
  }
}

fn go_deepest_down(zipper: rose_tree.Zipper(Int)) -> rose_tree.Zipper(Int) {
  case rose_tree.go_down(zipper) {
    Ok(z) -> go_deepest_down(z)
    Error(_) -> zipper
  }
}

pub fn main() {
  // Balanced (full) trees
  let full_3_3 = build_balanced_rose_tree(3, 3)
  let full_7_3 = build_balanced_rose_tree(7, 3)
  let full_11_3 = build_balanced_rose_tree(11, 3)
  let full_3_10 = build_balanced_rose_tree(3, 10)
  let full_4_10 = build_balanced_rose_tree(4, 10)
  let full_5_10 = build_balanced_rose_tree(5, 10)

  // Linear trees
  let linear_10 = build_linear_rose_tree(10)
  let linear_1000 = build_linear_rose_tree(1000)
  let linear_100000 = build_linear_rose_tree(100_000)

  // Wide trees
  let wide_10 = build_wide_rose_tree(10)
  let wide_1000 = build_wide_rose_tree(1000)
  let wide_100000 = build_wide_rose_tree(100_000)

  // User trees for adapter benchmarks
  let my_full_3_3 = to_my_rose_tree(full_3_3)
  let my_full_7_3 = to_my_rose_tree(full_7_3)
  let my_full_11_3 = to_my_rose_tree(full_11_3)
  let my_full_3_10 = to_my_rose_tree(full_3_10)
  let my_full_4_10 = to_my_rose_tree(full_4_10)
  let my_full_5_10 = to_my_rose_tree(full_5_10)
  let my_linear_10 = to_my_rose_tree(linear_10)
  let my_linear_1000 = to_my_rose_tree(linear_1000)
  let my_linear_100000 = to_my_rose_tree(linear_100000)
  let my_wide_10 = to_my_rose_tree(wide_10)
  let my_wide_1000 = to_my_rose_tree(wide_1000)
  let my_wide_100000 = to_my_rose_tree(wide_100000)

  io.println("=== Rose Tree Conversion Benchmarks ===\n")

  io.println("--- from_standard_tree (RoseTree -> Zipper) ---")
  bench.run(
    [
      bench.Input("full d=11 w=3", full_11_3),
      bench.Input("full d=5 w=10", full_5_10),
      bench.Input("linear d=100000", linear_100000),
      bench.Input("wide w=100000", wide_100000),
    ],
    [bench.Function("from_standard_tree", rose_tree.from_standard_tree)],
    [bench.Duration(500), bench.Warmup(50)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.SD, bench.P(99)])
  |> io.println()

  io.println(
    "\n--- to_standard_tree (Zipper -> RoseTree, focus at deepest node) ---",
  )
  let deepest_full_11_3 =
    full_11_3 |> rose_tree.from_standard_tree |> go_deepest_down
  let deepest_full_5_10 =
    full_5_10 |> rose_tree.from_standard_tree |> go_deepest_down
  let deepest_linear_100000 =
    linear_100000 |> rose_tree.from_standard_tree |> go_deepest_down
  let deepest_wide_100000 =
    wide_100000 |> rose_tree.from_standard_tree |> go_deepest_down

  bench.run(
    [
      bench.Input("full d=11 w=3 (d=11)", deepest_full_11_3),
      bench.Input("full d=5 w=10 (d=5)", deepest_full_5_10),
      bench.Input("linear d=100000 (d=100000)", deepest_linear_100000),
      bench.Input("wide w=100000 (d=1)", deepest_wide_100000),
    ],
    [bench.Function("to_standard_tree", rose_tree.to_standard_tree)],
    [bench.Duration(500), bench.Warmup(50)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.SD, bench.P(99)])
  |> io.println()

  io.println("\n--- from_tree (UserTree -> Zipper via adapter) ---")
  let adapter = my_rose_tree_adapter()

  bench.run(
    [
      bench.Input("full d=3 w=3", #(my_full_3_3, adapter)),
      bench.Input("full d=7 w=3", #(my_full_7_3, adapter)),
      bench.Input("full d=11 w=3", #(my_full_11_3, adapter)),
      bench.Input("full d=3 w=10", #(my_full_3_10, adapter)),
      bench.Input("full d=4 w=10", #(my_full_4_10, adapter)),
      bench.Input("full d=5 w=10", #(my_full_5_10, adapter)),
      bench.Input("linear d=10", #(my_linear_10, adapter)),
      bench.Input("linear d=1000", #(my_linear_1000, adapter)),
      bench.Input("linear d=100000", #(my_linear_100000, adapter)),
      bench.Input("wide w=10", #(my_wide_10, adapter)),
      bench.Input("wide w=1000", #(my_wide_1000, adapter)),
      bench.Input("wide w=100000", #(my_wide_100000, adapter)),
    ],
    [
      bench.Function("from_tree", fn(input) {
        let #(t, a) = input
        rose_tree.from_tree(t, a)
      }),
    ],
    [bench.Duration(500), bench.Warmup(50)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.SD, bench.P(99)])
  |> io.println()

  io.println("\n--- to_tree (Zipper -> UserTree via adapter) ---")
  let z_full_3_3 = rose_tree.from_standard_tree(full_3_3)
  let z_full_7_3 = rose_tree.from_standard_tree(full_7_3)
  let z_full_11_3 = rose_tree.from_standard_tree(full_11_3)
  let z_full_3_10 = rose_tree.from_standard_tree(full_3_10)
  let z_full_4_10 = rose_tree.from_standard_tree(full_4_10)
  let z_full_5_10 = rose_tree.from_standard_tree(full_5_10)
  let z_linear_10 = rose_tree.from_standard_tree(linear_10)
  let z_linear_1000 = rose_tree.from_standard_tree(linear_1000)
  let z_linear_100000 = rose_tree.from_standard_tree(linear_100000)
  let z_wide_10 = rose_tree.from_standard_tree(wide_10)
  let z_wide_1000 = rose_tree.from_standard_tree(wide_1000)
  let z_wide_100000 = rose_tree.from_standard_tree(wide_100000)

  bench.run(
    [
      bench.Input("full d=3 w=3", #(z_full_3_3, adapter)),
      bench.Input("full d=7 w=3", #(z_full_7_3, adapter)),
      bench.Input("full d=11 w=3", #(z_full_11_3, adapter)),
      bench.Input("full d=3 w=10", #(z_full_3_10, adapter)),
      bench.Input("full d=4 w=10", #(z_full_4_10, adapter)),
      bench.Input("full d=5 w=10", #(z_full_5_10, adapter)),
      bench.Input("linear d=10", #(z_linear_10, adapter)),
      bench.Input("linear d=1000", #(z_linear_1000, adapter)),
      bench.Input("linear d=100000", #(z_linear_100000, adapter)),
      bench.Input("wide w=10", #(z_wide_10, adapter)),
      bench.Input("wide w=1000", #(z_wide_1000, adapter)),
      bench.Input("wide w=100000", #(z_wide_100000, adapter)),
    ],
    [
      bench.Function("to_tree", fn(input) {
        let #(z, a) = input
        rose_tree.to_tree(z, a)
      }),
    ],
    [bench.Duration(500), bench.Warmup(50)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.SD, bench.P(99)])
  |> io.println()
}
