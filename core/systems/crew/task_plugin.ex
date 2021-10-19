defmodule Systems.Crew.TaskPlugin do
  @moduledoc """
  Generic behaviour of task
  """
  alias Systems.Crew.TaskPlugin.CallToAction
  alias Phoenix.Socket

  @type socket :: Socket.t()
  @type task :: binary
  @type event :: binary
  @type info_result :: %{
          call_to_action: CallToAction.t(),
        }
  @type get_cta_path_result :: binary

  @doc """
  Delivers info for the task landing page
  """
  @callback info(task, socket) :: info_result

  @doc """
  Handles event from call to action
  """
  @callback get_cta_path(task, event, socket) :: get_cta_path_result
end

defmodule Systems.Crew.TaskPlugin.CallToAction.Target do
  @moduledoc """
  """
  defstruct [:type, :value]

  @type t :: %__MODULE__{
          type: :event | :navigation,
          value: String.t()
        }
end

defmodule Systems.Crew.TaskPlugin.CallToAction do
  @moduledoc """
  """
  defstruct [:label, :target]

  @type t :: %__MODULE__{
          label: String.t(),
          target: Core.Promotions.CallToAction.Target.t()
        }
end
