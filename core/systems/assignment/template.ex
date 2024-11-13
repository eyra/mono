defprotocol Systems.Assignment.Template do
  alias Systems.Assignment.Template

  @type title :: binary()
  @type tabs :: [
          settings: {title(), Template.Flags.Settings.t()} | nil,
          import: {title(), Template.Flags.Import.t()} | nil,
          criteria: {title(), Template.Flags.Criteria.t()} | nil,
          participants: {title(), Template.Flags.Participants.t()} | nil,
          workflow: {title(), Template.Flags.Workflow.t()} | nil,
          monitor: {binary(), Template.Flags.Monitor.t()} | nil
        ]

  @spec title(t) :: binary()
  def title(t)

  @spec tabs(t) :: tabs()
  def tabs(t)

  @spec workflow_config(t) :: Systems.Workflow.Config.t()
  def workflow_config(t)
end

defmodule Systems.Assignment.Template.Flags do
  defmacro __using__(flags) do
    quote do
      @type t :: %__MODULE__{
              unquote_splicing(
                for flag <- flags do
                  {flag, {:boolean, [], []}}
                end
              )
            }

      defstruct unquote(flags)

      def new(opts \\ []) do
        opt_out_flag = Keyword.get(opts, :opt_out, [])

        unquote(flags)
        |> Enum.map(fn flag -> {flag, not Enum.member?(opt_out_flag, flag)} end)
        |> Enum.into(%{})
      end
    end
  end
end

defmodule Systems.Assignment.Template.Flags.Settings do
  use Systems.Assignment.Template.Flags, [
    :expected,
    :language,
    :branding,
    :information,
    :privacy,
    :consent,
    :helpdesk,
    :storage,
    :panel
  ]
end

defmodule Systems.Assignment.Template.Flags.Participants do
  use Systems.Assignment.Template.Flags, [
    :advert_in_pool,
    :invite_participants
  ]
end

defmodule Systems.Assignment.Template.Flags.Import do
  use Systems.Assignment.Template.Flags, []
end

defmodule Systems.Assignment.Template.Flags.Criteria do
  use Systems.Assignment.Template.Flags, []
end

defmodule Systems.Assignment.Template.Flags.Workflow do
  use Systems.Assignment.Template.Flags, [:library]
end

defmodule Systems.Assignment.Template.Flags.Monitor do
  use Systems.Assignment.Template.Flags, [:consent]
end
