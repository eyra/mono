defmodule Systems.Pool.BrandingModel do
  @moduledoc """
  This schema contains branding fields of pools.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema
  import Ecto.Changeset

  @fields ~w(title description logo_url)a
  @required_fields @fields

  schema "pool_branding" do
    field(:title, :string)
    field(:description, :string)
    field(:logo_url, :string)
  end

  def changeset(branding, attrs \\ %{}) do
    cast(branding, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([])
end
