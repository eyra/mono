defmodule Systems.Annotation.Pattern.Retraction do
  @moduledoc """
  A pattern for creating a Retraction Annotation.
  A Retraction is way to express that a previous Annotation is no longer valid.
  """

  alias Core.Authentication
  alias Systems.Annotation

  @type t :: %__MODULE__{
          reason: String.t() | nil,
          annotation: Annotation.Model.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:reason, :annotation, :entity]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers

    @retraction "Retraction"
    @subject "Subject"

    def obtain(%{reason: nil}), do: raise(MissingFieldError, :reason)
    def obtain(%{annotation: nil}), do: raise(MissingFieldError, :annotation)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          reason: reason,
          annotation: annotation,
          entity: entity
        }) do
      if annotation = get(reason: reason, annotation: annotation, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@retraction, entity)
        annotation_ref = obtain_annotation_ref!({:annotation, {@subject, annotation}}, entity)
        annotation = insert_annotation!(type, reason, entity, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{reason: reason, annotation: annotation, entity: entity}) do
      {:ok, query(reason, annotation, entity)}
    end

    defp query(reason, annotation, entity) do
      query_annotation(@retraction, reason, entity, {:annotation, {@subject, annotation}})
    end

    defp get(reason: reason, annotation: annotation, entity: entity) do
      query(reason, annotation, entity)
      |> Repo.one()
    end
  end
end
