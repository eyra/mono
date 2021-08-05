defmodule Core.Survey.FormData do
  @moduledoc """
  The schema for the survey form.
  """
  use Ecto.Schema
  use Timex

  import Ecto.Changeset

  alias Core.Enums.Devices
  require Core.Enums.Devices

  embedded_schema do
    # Plain Data
    field(:survey_url, :string)
    field(:subject_count, :string)
    field(:duration, :string)
    field(:reward_value, :string)
    # Rich Data (Transient)
    field(:device_labels, {:array, :any})
  end

  @fields ~w(survey_url subject_count duration reward_value)a

  def changeset(form_data, _, params) do
    form_data
    |> cast(params, @fields)
  end

  def create(tool) do
    tool_opts = Map.take(tool, @fields)
    transient_opts = create_transient_opts(tool)

    opts =
      %{}
      |> Map.merge(tool_opts)
      |> Map.merge(transient_opts)

    struct(Core.Survey.FormData, opts)
  end

  defp create_transient_opts(tool) do
    %{device_labels: Devices.labels(tool.devices)}
  end
end
