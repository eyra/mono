defmodule Systems.Annotation.Pattern.Objection do
  @moduledoc """
  A pattern for creating a Objection Annotation.
  An Objection is a negative vote in the context of a Sociocratic consent-based decision making round.
  """

  alias Core.Authentication
  alias Systems.Ontology

  @type t :: %__MODULE__{
          reason: String.t() | nil,
          subject: Ontology.ConceptModel.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:reason, :subject, :entity]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers

    @objection "Objection"
    @subject "Subject"

    def obtain(%{reason: nil}), do: raise(MissingFieldError, :reason)
    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          reason: reason,
          subject: subject,
          entity: entity
        }) do
      if annotation = get(reason: reason, subject: subject, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@objection, entity)
        annotation_ref = obtain_annotation_ref!({:concept, {@subject, subject}}, entity)
        annotation = insert_annotation!(type, reason, entity, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{reason: reason, subject: subject, entity: entity}) do
      {:ok, query(reason, subject, entity)}
    end

    defp query(reason, subject, entity) do
      query_annotation(@objection, reason, entity, {:concept, {@subject, subject}})
    end

    defp get(reason: reason, subject: subject, entity: entity) do
      query(reason, subject, entity)
      |> Repo.one()
    end
  end
end
