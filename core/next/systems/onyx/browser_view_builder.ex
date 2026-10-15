defmodule Systems.Onyx.BrowserViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Annotation
  alias Systems.Ontology
  alias Systems.Onyx

  @filter_keys %{
    :root => [:annotation, :concept, :predicate],
    Systems.Ontology.ConceptModel => [:annotation, :predicate],
    Systems.Ontology.PredicateModel => [:annotation, :concept],
    Systems.Annotation.Model => [:annotation, :concept, :predicate]
  }

  @max_history_count 6
  @max_card_count 100

  def view_model(%{id: :root}, assigns) do
    view_model(nil, @filter_keys[:root], [], assigns)
  end

  def view_model(%module{} = model, %{history: history} = assigns) do
    history_cards =
      history
      |> Enum.reverse()
      |> Enum.take(@max_history_count)
      |> Enum.reverse()
      |> Enum.map(&map_to_card(&1, :tertiary))

    view_model(model, @filter_keys[module], history_cards, assigns)
  end

  def view_model(
        model,
        filter_keys,
        history_cards,
        %{entities: entities, history: history, query: query} = assigns
      )
      when is_list(filter_keys) do
    active_filters = Map.get(assigns, :active_filters, []) |> Enum.map(&String.to_existing_atom/1)
    filters = Enum.map(filter_keys, &map_to_filter(&1, Enum.member?(active_filters, &1)))

    # Make sure to include all filters if no active filters are set
    model_filters =
      case active_filters do
        [] -> filter_keys
        active_filters -> active_filters
      end

    cards =
      get_models(model_filters, entities, model)
      |> Enum.filter(fn model ->
        matches_query?(model, query)
      end)
      |> Enum.map(&map_to_card(&1, :secondary))

    %{
      filters: filters,
      history_count: Enum.count(history),
      history_cards: history_cards,
      card_count: Enum.count(cards),
      cards: cards |> Enum.take(@max_card_count),
      entities: entities
    }
  end

  defp map_to_filter(:annotation, active?) do
    %{
      id: :annotation,
      value: dgettext("eyra-onyx", "browser.filter.annotation"),
      active: active?
    }
  end

  defp map_to_filter(:concept, active?) do
    %{
      id: :concept,
      value: dgettext("eyra-onyx", "browser.filter.concept"),
      active: active?
    }
  end

  defp map_to_filter(:predicate, active?) do
    %{
      id: :predicate,
      value: dgettext("eyra-onyx", "browser.filter.predicate"),
      active: active?
    }
  end

  defp get_models(active_filters, entities, model) when is_list(active_filters) do
    Enum.reduce(active_filters, [], fn filter, acc ->
      acc ++ get_models(filter, entities, model)
    end)
  end

  defp get_models(:annotation, entities, nil) do
    Annotation.Public.list_annotations(entities, Annotation.Model.preload_graph(:down))
  end

  defp get_models(:annotation, entities, %{} = model) do
    Annotation.Public.list_annotations({model, entities}, Annotation.Model.preload_graph(:down))
  end

  defp get_models(:concept, _entities, nil) do
    Ontology.Public.list_concepts(Ontology.ConceptModel.preload_graph(:down))
  end

  defp get_models(:concept, _entities, %Annotation.Model{} = model) do
    Ontology.Element.flatten(model)
    |> Enum.filter(fn %module{} -> module == Ontology.ConceptModel end)
    |> Enum.uniq_by(& &1.id)
  end

  defp get_models(:concept, _entities, %Ontology.PredicateModel{} = model) do
    Ontology.Element.flatten(model)
  end

  defp get_models(:predicate, _entities, nil) do
    Ontology.Public.list_predicates(Ontology.PredicateModel.preload_graph(:down))
  end

  defp get_models(:predicate, _entities, %Annotation.Model{} = model) do
    Ontology.Element.flatten(model)
    |> Enum.filter(fn %module{} -> module == Ontology.PredicateModel end)
    |> Enum.uniq_by(& &1.id)
  end

  defp get_models(:predicate, _entities, %Ontology.ConceptModel{} = model) do
    Ontology.Public.list_predicates(model, Ontology.PredicateModel.preload_graph(:down))
  end

  defp matches_query?(_, nil), do: true
  defp matches_query?(_, []), do: true

  defp matches_query?(text, query) when is_binary(text) do
    Enum.any?(query, &String.contains?(text, &1))
  end

  defp matches_query?(%Ontology.ConceptModel{phrase: phrase}, query) do
    matches_query?(phrase, query)
  end

  defp matches_query?(
         %Ontology.PredicateModel{subject: subject, type: type, object: object},
         query
       ) do
    matches_query?(subject, query) or matches_query?(type, query) or matches_query?(object, query)
  end

  defp matches_query?(%Annotation.Model{type: type, statement: statement}, query) do
    matches_query?(type, query) or matches_query?(statement, query)
  end

  defp map_to_card(model, type) do
    Onyx.Private.map_to_card(model, type)
  end
end
