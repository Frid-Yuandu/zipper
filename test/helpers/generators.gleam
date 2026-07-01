import qcheck

/// Creates a recursive generator from a non-recursive seed.
///
/// The given function receives a continuation generator and a size hint. It
/// can call the continuation with a smaller size to build recursive structures
/// that terminate once the size reaches zero.
///
/// ## Examples
///
/// ```gleam
/// fn gen_tree() {
///   let generator = {
///     use self, size <- fixpoint
///     case size {
///       0 -> qcheck.return(tree.Leaf)
///       n -> {
///         use value <- qcheck.bind(qcheck.small_non_negative_int())
///         use left <- qcheck.map(self(n / 2))
///         use right <- qcheck.map(self(n / 2))
///         qcheck.return(tree.Node(value, left, right))
///       }
///     }
///   }
///   qcheck.sized_from(generator, qcheck.small_non_negative_int())
/// }
/// ```
pub fn fixpoint(
  f: fn(fn(a) -> qcheck.Generator(b), a) -> qcheck.Generator(b),
) -> fn(a) -> qcheck.Generator(b) {
  fn(x) { f(fixpoint(f), x) }
}
