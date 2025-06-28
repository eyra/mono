defmodule Systems.Annotation.Pattern.Consent do
  @moduledoc """
  A pattern for creating a Consent Annotation.
  A Consent is a positive vote in the context of a Sociocratic consent-based decision making round.
  """

  alias Core.Authentication
  alias Systems.Ontology

  @type t :: %__MODULE__{
          subject: Ontology.ConceptModel.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:subject, :entity]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers

    @consent "Consent"
    @subject "Subject"

    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          subject: subject,
          entity: entity
        }) do
      if annotation = get(subject: subject, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@consent, entity)
        annotation_ref = obtain_annotation_ref!({:concept, {@subject, subject}}, entity)
        annotation = insert_annotation!(type, @consent, entity, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{subject: subject, entity: entity}) do
      {:ok, query(subject, entity)}
    end

    defp query(subject, entity) do
      query_annotation(@consent, @consent, entity, {:concept, {@subject, subject}})
    end

    defp get(subject: subject, entity: entity) do
      query(subject, entity)
      |> Repo.one()
    end
  end
end
