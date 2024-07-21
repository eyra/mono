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
          expected: boolean(),
          language: boolean(),
          branding: boolean(),
          information: boolean(),
          privacy: boolean(),
          consent: boolean(),
          helpdesk: boolean(),
          panel: boolean(),
          storage: boolean(),
          invite_participants: boolean(),
          advert_in_pool: boolean(),
          workflow: boolean(),
          monitor: boolean()
        }

  @keys [
    :expected,
    :language,
    :branding,
    :information,
    :privacy,
    :consent,
    :helpdesk,
    :storage,
    :panel,
    :advert_in_pool,
    :invite_participants,
    :workflow,
    :monitor
  ]

  defstruct @keys

  def new(opts \\ []) do
    opt_out_keys = Keyword.get(opts, :opt_out, [])

    @keys
    |> Enum.map(fn key -> {key, not Enum.member?(opt_out_keys, key)} end)
    |> Enum.into(%{})
  end
end
