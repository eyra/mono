defmodule Systems.Onyx.Private do
  alias Core.Repo
  alias Core.Authentication
  alias CoreWeb.UI.Timestamp
  alias Systems.Ontology
  alias Systems.Annotation

  def map_to_card(%{entity: %Ecto.Association.NotLoaded{}} = model, type) do
    map_to_card(Repo.preload(model, :entity), type)
  end

  def map_to_card(
        %Ontology.ConceptModel{id: id, phrase: phrase, entity: entity, inserted_at: inserted_at},
        card_type
      ) do
    entity_name =
      Authentication.fetch_subject(entity)
      |> Authentication.Subject.name()

    %{
      type: card_type,
      id: "#{card_type}-concept-#{id}",
      title: phrase,
      tags: ["Concept"],
      info: "Created #{Timestamp.humanize(inserted_at)} by #{entity_name}",
      model: {Systems.Ontology.ConceptModel, id}
    }
  end

  def map_to_card(
        %Ontology.PredicateModel{
          id: id,
          subject: %{phrase: subject_phrase},
          type: type,
          object: %{phrase: object_phrase},
          entity: entity,
          inserted_at: inserted_at
        },
        card_type
      ) do
    entity_name =
      Authentication.fetch_subject(entity)
      |> Authentication.Subject.name()

    title =
      "#{subject_phrase} #{predicate_type_to_string(type)} #{object_phrase}"

    %{
      type: card_type,
      id: "#{card_type}-predicate-#{id}",
      title: title,
      tags: ["Predicate"],
      info: "Created #{Timestamp.humanize(inserted_at)} by #{entity_name}",
      model: {Systems.Ontology.PredicateModel, id}
    }
  end

  def map_to_card(
        %Annotation.Model{
          id: id,
          type: type,
          statement: statement,
          entity: entity,
          inserted_at: inserted_at,
          references: references
        },
        card_type
      ) do
    entity_name =
      Authentication.fetch_subject(entity)
      |> Authentication.Subject.name()

    reference_summaries = references |> Enum.map(&Annotation.Public.summarize/1)

    %{
      type: card_type,
      id: "#{card_type}-annotation-#{id}",
      title: statement,
      tags: ["Annotation", type.phrase] ++ reference_summaries,
      info: "Created #{Timestamp.humanize(inserted_at)} by #{entity_name}",
      model: {Systems.Annotation.Model, id}
    }
  end

  def predicate_type_to_string(type) do
    case type.phrase do
      "Subsumes" -> ":>"
      "Composes" -> "*>"
      "Compares" -> "~"
      "Influences" -> ">"
      "Transforms" -> ">>"
      "Interacts" -> "<>"
      "Locates" -> "@>"
      phrase -> phrase
    end
  end
end
