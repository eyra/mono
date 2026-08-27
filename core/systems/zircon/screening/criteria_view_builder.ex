defmodule Systems.Zircon.Screening.CriteriaViewBuilder do
  @moduledoc false
  import Systems.Zircon.Private, only: [list_research_dimensions: 0, list_research_frameworks: 0]

  alias Core.Authentication
  alias Frameworks.Builder
  alias Systems.Annotation
  alias Systems.Ontology

  @parameter Systems.Annotation.Pattern.Parameter.type_phrase()

  def view_model(%{annotations: annotations}, _assigns) do
    actor = Authentication.obtain_actor!(:system, "Zircon")
    entity = Authentication.obtain_entity!(actor)

    dimension_list = list_research_dimensions()

    library_items =
      {dimension_list, list_research_frameworks()}
      |> get_library_map(entity)
      |> get_library_items()
      |> Enum.sort_by(& &1.title)

    criteria_list =
      annotations
      |> Enum.sort_by(& &1.inserted_at, :asc)
      |> Enum.filter(fn annotation -> annotation.type.phrase == @parameter end)

    %{
      dimension_list: dimension_list,
      library_items: library_items,
      criteria_list: criteria_list
    }
  end

  defp get_library_map({dimension_list, framework_list}, entity) do
    Enum.reduce(dimension_list, %{}, fn dimension, acc ->
      definition = Annotation.Public.get_most_recent_definition(dimension, entity)

      frameworks =
        dimension.phrase
        |> Ontology.Public.get_categories_for_member()
        |> Enum.filter(fn framework -> Enum.member?(framework_list, framework) end)
        |> Enum.map(& &1.phrase)

      Map.put(acc, dimension, %{definition: definition, frameworks: frameworks})
    end)
  end

  defp get_library_items(%{} = dimension_framework_map) do
    Enum.map(dimension_framework_map, fn {dimension, %{definition: definition, frameworks: frameworks}} ->
      %Builder.LibraryItemModel{
        id: dimension.phrase,
        type: "Research Dimension",
        title: dimension.phrase,
        tags: frameworks,
        description: definition
      }
    end)
  end
end
