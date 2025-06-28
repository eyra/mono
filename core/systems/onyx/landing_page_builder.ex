defmodule Systems.Onyx.LandingPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Authentication
  alias Systems.Ontology
  alias Systems.Annotation
  alias Systems.Onyx

  @tab_keys [:annotation, :concept, :predicate]

  def view_model(%{id: :singleton}, %{current_user: user} = assigns) do
    user_entity = Authentication.obtain_entity!(user)
    system_actor = Authentication.obtain_actor!(:system, "Onyx")
    system_entity = Authentication.obtain_entity!(system_actor)

    %{
      tabbar_id: "onyx_landing",
      title: dgettext("eyra-onyx", "landing.title"),
      active_menu_item: :onyx,
      show_errors: false,
      entities: [user_entity, system_entity]
    }
    |> put_tabs(assigns)
  end

  defp put_tabs(vm, assigns) do
    Map.put(vm, :tabs, create_tabs(vm, assigns))
  end

  defp create_tabs(vm, assigns) do
    @tab_keys
    |> Enum.map(&create_tab(&1, vm, assigns))
  end

  defp create_tab(:concept, %{entities: entities}, %{current_user: user}) do
    title = dgettext("eyra-onyx", "concept.tab.title")
    concepts = Ontology.Public.list_concepts(entities, [:entity])

    element =
      LiveNest.Element.prepare_live_view(
        :landing_page_concept,
        Onyx.ConceptTab,
        title: title,
        concepts: concepts,
        user: user,
        depth: 1
      )

    %{
      id: :landing_page_concept,
      ready: false,
      show_errors: false,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      element: element
    }
  end

  defp create_tab(:predicate, %{entities: entities}, %{current_user: user}) do
    title = dgettext("eyra-onyx", "predicate.tab.title")
    predicates = Ontology.Public.list_predicates(entities, [:entity, :subject, :type, :object])

    element =
      LiveNest.Element.prepare_live_view(
        :landing_page_predicate,
        Onyx.PredicateTab,
        title: title,
        predicates: predicates,
        user: user,
        depth: 1
      )

    %{
      id: :landing_page_predicate,
      ready: false,
      show_errors: false,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      element: element
    }
  end

  defp create_tab(:annotation, %{entities: entities}, %{current_user: user}) do
    title = dgettext("eyra-onyx", "annotation.tab.title")

    annotations =
      Annotation.Public.list_annotations(entities, Annotation.Model.preload_graph(:down))

    element =
      LiveNest.Element.prepare_live_view(
        :landing_page_annotation,
        Onyx.AnnotationTab,
        title: title,
        annotations: annotations,
        user: user,
        depth: 1
      )

    %{
      id: :landing_page_annotation,
      ready: false,
      show_errors: false,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      element: element
    }
  end
end
