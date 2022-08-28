defmodule Systems.Content.Context do
  import Ecto.Query, warn: false

  alias Core.Repo

  alias Systems.Content.TextItemModel, as: TextItem
  alias Systems.Content.TextBundleModel, as: TextBundle

  def get_text_item!(id, preload \\ []) do
    from(t in TextItem, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_text_bundle!(id, preload \\ []) do
    from(t in TextBundle, preload: ^preload)
    |> Repo.get!(id)
  end

  def create_text_item!(%{} = attrs, bundle) do
    %TextItem{}
    |> TextItem.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:bundle, bundle)
    |> Repo.insert!()
  end

  def create_text_bundle!(attrs \\ %{}) do
    %TextBundle{}
    |> TextBundle.changeset(attrs)
    |> Repo.insert!()
  end
end
