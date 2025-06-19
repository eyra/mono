defmodule Systems.Annotation.Recipe.Retraction do
  @moduledoc """
  A recipe for creating a Retraction Annotation.
  A Retraction is way to express that a previous Annotation is no longer valid.
  """

  alias Systems.Account
  alias Systems.Annotation

  @type t :: %__MODULE__{
          reason: String.t() | nil,
          annotation: Annotation.Model.t() | nil,
          author: Account.User.t() | nil
        }

  defstruct [:reason, :annotation, :author]

  defimpl Systems.Annotation.Recipe do
    use Systems.Annotation.Recipe.Helpers

    @retraction "Retraction"
    @subject "Subject"

    def obtain(%{reason: nil}), do: raise(MissingFieldError, :reason)
    def obtain(%{annotation: nil}), do: raise(MissingFieldError, :annotation)
    def obtain(%{author: nil}), do: raise(MissingFieldError, :author)

    def obtain(%{
          reason: reason,
          annotation: annotation,
          author: author
        }) do
      if annotation = get(reason: reason, annotation: annotation, author: author) do
        {:ok, annotation}
      else
        type = obtain_concept!(@retraction, author)
        annotation_ref = obtain_annotation_ref!({:annotation, {@subject, annotation}}, author)
        annotation = insert_annotation!(type, reason, author, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{reason: reason, annotation: annotation, author: author}) do
      {:ok, query(reason, annotation, author)}
    end

    defp query(reason, annotation, author) do
      query_annotation(@retraction, reason, author, {:annotation, {@subject, annotation}})
    end

    defp get(reason: reason, annotation: annotation, author: author) do
      query(reason, annotation, author)
      |> Repo.one()
    end
  end
end
