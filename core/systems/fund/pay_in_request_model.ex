defmodule Systems.Fund.PayInRequestModel do
  @moduledoc """
  Form-object for `Fund.Public.create_pay_in/3`. Holds the researcher's
  input in the "Add participants" modal: how many participants they want
  to fund, at what fee, plus the (persisted) study aim.

  Reward is stored in cents. `changeset/2` normalizes the raw display
  string (e.g. `"5,00"` / `"5.00"`) to cents before casting.

  Cast and validate are split (see `Systems.Content.FileModel`) so the
  view can echo the current input on every keystroke without forcing
  errors until the researcher hits Confirm.
  """
  use Ecto.Schema
  use Gettext, backend: CoreWeb.Gettext

  import Ecto.Changeset

  alias Systems.Assignment.CurrencyHelpers

  @primary_key false
  embedded_schema do
    field(:subject_count, :integer)
    field(:subject_reward, :integer)
    field(:aim_of_study, :string)
  end

  @fields ~w(subject_count subject_reward aim_of_study)a

  def changeset(%__MODULE__{} = request, attrs \\ %{}) do
    cast(request, normalize_reward(attrs), @fields)
  end

  def validate(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_positive(
      :subject_count,
      dgettext("eyra-assignment", "pay_in_request_form.slots.required")
    )
    |> validate_required([:subject_reward],
      message: dgettext("eyra-assignment", "pay_in_request_form.fee.required")
    )
    |> validate_required([:aim_of_study],
      message: dgettext("eyra-assignment", "pay_in_request_form.aim.required")
    )
    |> validate_length(:aim_of_study, max: 250)
  end

  defp validate_positive(changeset, field, message) do
    case get_field(changeset, field) do
      n when is_integer(n) and n > 0 -> changeset
      _ -> add_error(changeset, field, message)
    end
  end

  defp normalize_reward(%{"subject_reward" => ""} = attrs) do
    Map.put(attrs, "subject_reward", nil)
  end

  defp normalize_reward(%{"subject_reward" => raw} = attrs) when is_binary(raw) do
    case CurrencyHelpers.display_to_cents(raw) do
      {:ok, cents} -> Map.put(attrs, "subject_reward", cents)
      :error -> Map.put(attrs, "subject_reward", nil)
    end
  end

  defp normalize_reward(attrs), do: attrs
end
