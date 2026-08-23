defmodule Systems.Assignment.RuntimeConfig do
  @moduledoc """
  Configuration for participant-facing runtime behavior of an assignment.

  Returned by `Assignment.Template.runtime_config/1` and consumed by the
  parts of the system that need to know which pool a template targets —
  today: the finished view (post-completion email capture) and the
  participants view (advert-in-pool CTA).

  ## Fields

    * `:pool` — atom slug of the pool this template targets, e.g. `:panl`.
      `nil` means the template is not pool-scoped.
  """

  @type t :: %__MODULE__{
          pool: atom() | nil
        }

  defstruct pool: nil
end
