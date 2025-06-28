defmodule Systems.Annotation.Pattern.Definition do
  alias Core.Authentication
  alias Systems.Ontology

  @type t :: %__MODULE__{
          definition: String.t() | nil,
          subject: Ontology.ConceptModel.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:definition, :subject, :entity]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers

    def obtain(%{definition: nil}), do: raise(MissingFieldError, :definition)
    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          definition: definition,
          subject: subject,
          entity: entity
        }) do
      if annotation = get(definition: definition, subject: subject, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@definition, entity)
        annotation_ref = obtain_annotation_ref!({:concept, {@subject, subject}}, entity)
        annotation = insert_annotation!(type, definition, entity, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{definition: definition, subject: subject, entity: entity}) do
      {:ok, query(definition, subject, entity)}
    end

    defp query(definition, subject, entity) do
      query_annotation(@definition, definition, entity, {:concept, {@subject, subject}})
    end

    defp get(definition: definition, subject: subject, entity: entity) do
      query(definition, subject, entity)
      |> Repo.one()
    end
  end
end
