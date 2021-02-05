defmodule Link.Authorization.Node do
  use Ecto.Schema

  schema "authorization_nodes" do
    belongs_to :parent, Link.Authorization.Node
    timestamps()
  end
end
