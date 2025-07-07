defmodule Systems.Annotation.Pattern.Connection do
  @moduledoc """
  A pattern for creating a Connection Annotation.
  A Connection is way to express that two annotations are related.
  """

  alias Core.Authentication
  alias Systems.Annotation

  @type t :: %__MODULE__{
          statement: String.t() | nil,
          subject: Annotation.Model.t() | nil,
          object: Annotation.Model.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:statement, :subject, :object, :entity]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers
    import Ecto.Query, warn: true

    @connection "Connection"

    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{statement: nil}), do: raise(MissingFieldError, :statement)
    def obtain(%{object: nil}), do: raise(MissingFieldError, :object)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          subject: subject,
          statement: statement,
          object: object,
          entity: entity
        }) do
      if annotation = get(subject: subject, statement: statement, object: object, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@connection, entity)
        subject_ref = obtain_annotation_ref!(subject)
        object_ref = obtain_annotation_ref!(object)
        annotation = insert_annotation!(type, statement, entity, [subject_ref, object_ref])
        {:ok, annotation}
      end
    end

    def query(%{subject: subject, statement: statement, object: object, entity: entity}) do
      {:ok, query(subject, statement, object, entity)}
    end

    defp query(subject, statement, object, entity) do
      query_annotation(@connection, statement, entity)
      |> where([annotation: a, annotation_ref: ar], a.id in [^subject.id, ^object.id])
      |> having([annotation_ref: ar], count(ar.id) == 2)
    end

    defp get(subject: subject, statement: statement, object: object, entity: entity) do
      query(subject, statement, object, entity)
      |> Repo.one()
    end
  end
end
