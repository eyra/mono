# Shared setup lives in mica/test/test_helper.exs; mix test loads every test path helper.

# Start Wallaby for feature tests
{:ok, _} = Application.ensure_all_started(:wallaby)
