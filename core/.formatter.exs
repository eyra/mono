# Styler hoists `use` to the top of a module. These modules feed module
# attributes into the macro they `use`, or depend on the order in which the
# macros they `use` inject code, so hoisting breaks them.
styler_unsafe = ["lib/core_web.ex" | Path.wildcard("bundles/*/lib/layouts/*/menu_builder.ex")]

[
  import_deps: [:phoenix],
  plugins: [Styler],
  inputs:
    Enum.flat_map(
      ["*.{ex,exs}", "{bundles,config,frameworks,lib,systems,test}/**/*.{ex,exs}"],
      &Path.wildcard(&1, match_dot: true)
    ) -- styler_unsafe
]
