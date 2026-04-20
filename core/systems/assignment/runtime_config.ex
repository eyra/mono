defmodule Systems.Assignment.RuntimeConfig do
  @moduledoc """
  Configuration for participant-facing runtime behavior of an assignment.

  Returned by `Assignment.Template.runtime_config/1` and used by the
  crew page / finished view to drive post-completion actions.

  ## Post-actions

    * `{:add_to_pool, :panl}` — capture email and add user to the named pool (atom is the slug of the pool name)
    * `nil` — no post-completion action (default)
  """

  @type post_action :: {:add_to_pool, atom()} | nil

  @type t :: %__MODULE__{
          post_action: post_action()
        }

  defstruct post_action: nil
end
