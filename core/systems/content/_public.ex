defmodule Systems.Content.Public do
  import Ecto.Query, warn: false

  alias Systems.{
    Content
  }

  alias Core.Repo
  alias Ecto.Multi

  alias Systems.Content.TextItemModel, as: TextItem
  alias Systems.Content.TextBundleModel, as: TextBundle

  def store(file) do
    Content.Private.get_backend().store(file)
  end

  def get_public_url(id) do
    Content.Private.get_backend().get_public_url(id)
  end

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
    |> TextItem.change(attrs)
    |> Ecto.Changeset.put_assoc(:bundle, bundle)
    |> Repo.insert!()
  end

  def create_text_bundle!() do
    %TextBundle{}
    |> TextBundle.change(%{})
    |> Repo.insert!()
  end

  def create_text_bundle([_ | _] = items) do
    Multi.new()
    |> Multi.run(:bundle, fn _, _ ->
      {
        :ok,
        create_text_bundle!()
      }
    end)
    |> Multi.run(:items, fn _, %{bundle: bundle} ->
      {
        :ok,
        items
        |> Enum.map(&translate_item(&1))
        |> Enum.map(&create_text_item!(&1, bundle))
      }
    end)
    |> Repo.transaction()
  end

  defp translate_item({locale, text}), do: %{locale: Atom.to_string(locale), text: text}

  defp translate_item({locale, single, plural}),
    do: %{locale: Atom.to_string(locale), text: single, text_plural: plural}
end
