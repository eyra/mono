defmodule Systems.Zircon.Screening.CriteriaViewBuilder do
  import Systems.Zircon.Private, only: [list_research_dimensions: 0, list_research_frameworks: 0]

  alias Frameworks.Builder

  alias Core.Authentication
  alias Systems.Annotation
  alias Systems.Ontology

  def view_model(_model, _assigns) do
    actor = Authentication.obtain_actor!(:system, "Zircon")
    entity = Authentication.obtain_entity!(actor)

    library_items =
      {list_research_dimensions(), list_research_frameworks()}
      |> get_library_map(entity)
      |> get_library_items()
      |> Enum.sort_by(& &1.title)

    %{
      library_items: library_items
    }
  end

  defp get_library_map({dimension_list, framework_list}, entity) do
    Enum.reduce(dimension_list, %{}, fn dimension, acc ->
      definition =
        dimension
        |> Annotation.Public.get_most_recent_definition(entity)

      frameworks =
        dimension.phrase
        |> Ontology.Public.get_categories_for_member()
        |> Enum.filter(fn framework -> framework_list |> Enum.member?(framework) end)
        |> Enum.map(& &1.phrase)

      Map.put(acc, dimension, %{definition: definition, frameworks: frameworks})
    end)
  end

  defp get_library_items(%{} = dimension_framework_map) do
    dimension_framework_map
    |> Enum.map(fn {dimension, %{definition: definition, frameworks: frameworks}} ->
      %Builder.LibraryItemModel{
        id: dimension.phrase |> slugify(),
        type: :research_design_element,
        title: dimension.phrase,
        tags: frameworks,
        description: definition
      }
    end)
  end

  defp slugify(nil), do: "?"

  defp slugify(title) do
    title |> Slug.slugify(separator: ?_)
  end
end
