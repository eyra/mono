defmodule Systems.Org.NodeViewBuilder do
  alias Systems.Org

  def view_model(node, %{is_admin?: is_admin?}) do
    changeset = Org.NodeModel.changeset(node, %{})

    %{
      changeset: changeset,
      is_admin?: is_admin?
    }
  end
end
