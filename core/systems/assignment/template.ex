defprotocol Systems.Assignment.Template do
  @spec title(t) :: binary()
  def title(t)

  @spec content_flags(t) :: Systems.Assignment.ContentFlags.t()
  def content_flags(t)

  @spec workflow(t) :: Systems.Workflow.Config.t()
  def workflow(t)
end

defmodule Systems.Assignment.ContentFlags do
  @type t :: %__MODULE__{
          general: boolean(),
          branding: boolean(),
          information: boolean(),
          privacy: boolean(),
          consent: boolean(),
          helpdesk: boolean(),
          panel: boolean(),
          storage: boolean(),
          participants: boolean(),
          workflow: boolean(),
          monitor: boolean()
        }

  defstruct [
    :general,
    :branding,
    :information,
    :privacy,
    :consent,
    :helpdesk,
    :panel,
    :storage,
    :participants,
    :workflow,
    :monitor
  ]

  def new() do
    %__MODULE__{
      general: true,
      branding: true,
      information: true,
      privacy: true,
      consent: true,
      helpdesk: true,
      panel: true,
      storage: true,
      participants: true,
      workflow: true,
      monitor: true
    }
  end
end
