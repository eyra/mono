defmodule Systems.Affiliate.UserInfoModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Affiliate

  schema "affiliate_user_info" do
    field(:info, :string)

    belongs_to(:user, Affiliate.User)
    belongs_to(:affiliate, Affiliate.Model)

    timestamps()
  end

  @fields ~w(info)a
  @required_fields ~w(info)a

  def changeset(info, %{info: %{} = info} = attrs) do
    changeset(info, %{attrs | info: encode_info(info)})
  end

  def changeset(info, attrs) do
    cast(info, attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :affiliate_id], name: :affiliate_user_info_unique)
  end

  def preload_graph(:up), do: []
  def preload_graph(:down), do: []

  def encode_info(%{} = info) do
    Jason.encode!(info)
  end

  def decode_info(info) when is_binary(info) do
    Jason.decode!(info)
  end
end
