[
  # https://elixirforum.com/t/dialyzer-listed-not-implemented-protocols-as-unknown-functions/2099/12
  ~r/.*:unknown_function Function .*__impl__\/1 does not exist.*/,
  # Wallaby is a test-only dependency, Dialyzer can't find its functions
  ~r/test\/support\/feature_case.ex.*unknown_function Function Wallaby\..*/,
  # TODO: Fix error handling in DataDonationController with statement
  # The `with` clause has an unhandled error tuple pattern
  {"mica/systems/feldspar/data_donation_controller.ex", :apply},
  # httpoison 3.0.0's stream_next/1 keeps an error clause that hackney 4's
  # `stream_next/1 :: ok` spec rules out; it shows up in every `use HTTPoison.Base`
  {"deps/httpoison/lib/httpoison/base.ex", :callback_arg_type_mismatch},
  {"deps/httpoison/lib/httpoison/base.ex", :callback_type_mismatch},
  {"deps/httpoison/lib/httpoison/base.ex", :pattern_match_cov},
  ~r/^mica\/frameworks\/utility\/http_client\.ex:\d+:invalid_contract Invalid type specification for function stream_next\./
]
