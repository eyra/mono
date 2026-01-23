[
  # https://github.com/phoenixframework/phoenix/issues/5437, fixed in Phoenix 1.7.3 or higher
  {"systems/benchmark/export_controller.ex", :no_return},
  {"systems/benchmark/export_controller.ex", :call},
  # https://elixirforum.com/t/dialyzer-listed-not-implemented-protocols-as-unknown-functions/2099/12
  ~r/.*:unknown_function Function .*__impl__\/1 does not exist.*/,
  # Wallaby is a test-only dependency, Dialyzer can't find its functions
  ~r/test\/support\/feature_case.ex.*unknown_function Function Wallaby\..*/
]
