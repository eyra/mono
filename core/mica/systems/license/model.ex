defmodule Systems.License.Model do
  @moduledoc """
  A license support gave a user until an end date (`valid_until`, the last day
  it counts), with who gave it and when, and once switched off, who switched it
  off and when. The newest record of a user and license is that license's
  state; giving it again adds a record, so earlier ones stay as its history.
  `granted_by_system` marks a license given by no one (the transition, a seed):
  without it, an empty `granted_by` means the giver deleted their account.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account.User

  @licenses [:publish, :pay_in]

  schema "licenses" do
    belongs_to(:user, User)
    field(:license, Ecto.Enum, values: @licenses)
    field(:valid_until, :date)
    field(:granted_at, :utc_datetime)
    belongs_to(:granted_by, User)
    field(:granted_by_system, :boolean, default: false)
    field(:revoked_at, :utc_datetime)
    belongs_to(:revoked_by, User)

    timestamps()
  end

  @type license :: :publish | :pay_in

  def licenses, do: @licenses

  def grant_changeset(%User{id: user_id}, license, %Date{} = valid_until, granted_by) do
    %__MODULE__{}
    |> change(%{
      user_id: user_id,
      license: license,
      valid_until: valid_until,
      granted_at: now(),
      granted_by_id: id(granted_by),
      granted_by_system: is_nil(granted_by)
    })
    |> validate_inclusion(:license, @licenses)
  end

  def revoke_changeset(%__MODULE__{} = record, revoked_by) do
    change(record, %{revoked_at: now(), revoked_by_id: id(revoked_by)})
  end

  @doc "Whether the license counts on `today`: not switched off and not past its end date."
  def active?(%__MODULE__{revoked_at: nil, valid_until: valid_until}, %Date{} = today),
    do: Date.compare(valid_until, today) != :lt

  def active?(_record, _today), do: false

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp id(%User{id: id}), do: id
  defp id(nil), do: nil
end
