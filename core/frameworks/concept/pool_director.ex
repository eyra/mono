defmodule Frameworks.Concept.PoolDirector do
  @type user :: map
  @type budget :: map
  @type submission :: map
  @type error :: map
  @type currency :: binary
  @type url_resolver :: (atom, list -> binary)
  @type plugin :: %{module: atom, props: map}

  @callback overview_plugin(user) :: plugin | nil
  @callback submission_plugin(user) :: plugin | nil

  @callback resolve_budget(currency, user) :: budget
  @callback inclusion_criteria() :: list(atom)
  @callback submit(submission_id :: integer) :: {:ok, submission} | {:error, error}
  @callback submit(submission_id :: integer) :: {:ok, submission} | {:error, error}
end
