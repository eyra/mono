defmodule Systems.Assignment.RuntimeConfig do
  @moduledoc """
  Configuration for participant-facing runtime behavior of an assignment.

  Returned by `Assignment.Template.runtime_config/1` and consumed by the
  parts of the system that need to know how a template behaves for
  participants — today: the finished view (post-completion email capture,
  and Back, shown exactly when the task list showed the done button), the
  participants view (advert-in-pool CTA) and the task list (done button).

  ## Fields

    * `:pool` — atom slug of the pool this template targets, e.g. `:panl`.
      `nil` means the template is not pool-scoped.
    * `:done_button_requires_redirect?` — when `true`, the task list shows its
      done button only when the participant's session has an end-of-workflow
      URL (`panel_info.redirect_url`). When `false`, the button is always shown.
  """

  @type t :: %__MODULE__{
          pool: atom() | nil,
          done_button_requires_redirect?: boolean()
        }

  defstruct pool: nil, done_button_requires_redirect?: false
end
