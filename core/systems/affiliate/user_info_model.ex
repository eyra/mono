defmodule Systems.Affiliate.UserInfoModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Affiliate

  schema "affiliate_user_info" do
    field(:info, :string)

    belongs_to(:user, Affiliate.User)

    timestamps()
  end

  @fields ~w(info)a
  @required_fields ~w(info)a

  def changeset(info, %{info: %{} = info_map} = attrs) do
    changeset(info, %{attrs | info: encode_info(info_map)})
  end

  def changeset(info, attrs) do
    cast(info, attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id], name: :affiliate_user_info_unique)
  end

  def preload_graph(:up), do: []
  def preload_graph(:down), do: []

  def encode_info(%{} = info_map) do
    Jason.encode!(info_map)
  end

  def decode_info(info_string) when is_binary(info_string) do
    Jason.decode!(info_string)
  end
end
