[
  # https://elixirforum.com/t/dialyzer-listed-not-implemented-protocols-as-unknown-functions/2099/12
  ~r/.*:unknown_function Function .*__impl__\/1 does not exist.*/,
  # Wallaby is a test-only dependency, Dialyzer can't find its functions
  ~r/test\/support\/feature_case.ex.*unknown_function Function Wallaby\..*/,
  # TODO: Fix error handling in DataDonationController with statement
  # The `with` clause has an unhandled error tuple pattern
  {"mica/systems/feldspar/data_donation_controller.ex", :apply}
]
