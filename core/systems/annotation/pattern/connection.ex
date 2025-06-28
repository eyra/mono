defmodule Systems.Annotation.Pattern.Connection do
  @moduledoc """
  A pattern for creating a Connection Annotation.
  A Connection is way to express that two annotations are related.
  """

  alias Core.Authentication
  alias Systems.Annotation

  @type t :: %__MODULE__{
          subject: Annotation.Model.t() | nil,
          relation: String.t() | nil,
          object: Annotation.Model.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:subject, :relation, :object, :entity]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers
    import Ecto.Query, warn: true

    @connection "Connection"
    @subject "Subject"
    @object "Object"

    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{relation: nil}), do: raise(MissingFieldError, :relation)
    def obtain(%{object: nil}), do: raise(MissingFieldError, :object)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          subject: subject,
          relation: relation,
          object: object,
          entity: entity
        }) do
      if annotation = get(subject: subject, relation: relation, object: object, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@connection, entity)
        subject_ref = obtain_annotation_ref!({:annotation, {@subject, subject}}, entity)
        object_ref = obtain_annotation_ref!({:annotation, {@object, object}}, entity)
        annotation = insert_annotation!(type, relation, entity, [subject_ref, object_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{subject: subject, relation: relation, object: object, entity: entity}) do
      {:ok, query(subject, relation, object, entity)}
    end

    defp query(subject, relation, object, entity) do
      query_annotation(@connection, relation, entity)
      |> where(
        [annotation: a, annotation_ref: ar],
        (ar.type_id == ^@subject and a.id == ^subject.id) or
          (ar.type_id == ^@object and a.id == ^object.id)
      )
      |> having([annotation_ref: ar], count(ar.id) == 2)
    end

    defp get(subject: subject, relation: relation, object: object, entity: entity) do
      query(subject, relation, object, entity)
      |> Repo.one()
    end
  end
end
