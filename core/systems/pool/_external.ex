defmodule Systems.Pool.External do
  @type user :: map
  @type budget :: map
  @type currency :: binary
  @type url_resolver :: (atom, list -> binary)
  @type plugin :: %{module: atom, props: map}

  @callback overview_plugin(user) :: plugin | nil
  @callback submission_plugin(user) :: plugin | nil

  @callback resolve_budget(currency, user) :: budget
  @callback inclusion_criteria() :: list(atom)
end
