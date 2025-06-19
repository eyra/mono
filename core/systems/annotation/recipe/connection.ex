defmodule Systems.Annotation.Recipe.Connection do
  @moduledoc """
  A recipe for creating a Connection Annotation.
  A Connection is way to express that two annotations are related.
  """

  alias Systems.Account
  alias Systems.Annotation

  @type t :: %__MODULE__{
          subject: Annotation.Model.t() | nil,
          relation: String.t() | nil,
          object: Annotation.Model.t() | nil,
          author: Account.User.t() | nil
        }

  defstruct [:subject, :relation, :object, :author]

  defimpl Systems.Annotation.Recipe do
    use Systems.Annotation.Recipe.Helpers
    import Ecto.Query, warn: true

    @connection "Connection"
    @subject "Subject"
    @object "Object"

    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{relation: nil}), do: raise(MissingFieldError, :relation)
    def obtain(%{object: nil}), do: raise(MissingFieldError, :object)
    def obtain(%{author: nil}), do: raise(MissingFieldError, :author)

    def obtain(%{
          subject: subject,
          relation: relation,
          object: object,
          author: author
        }) do
      if annotation = get(subject: subject, relation: relation, object: object, author: author) do
        {:ok, annotation}
      else
        type = obtain_concept!(@connection, author)
        subject_ref = obtain_annotation_ref!({:annotation, {@subject, subject}}, author)
        object_ref = obtain_annotation_ref!({:annotation, {@object, object}}, author)
        annotation = insert_annotation!(type, relation, author, [subject_ref, object_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{subject: subject, relation: relation, object: object, author: author}) do
      {:ok, query(subject, relation, object, author)}
    end

    defp query(subject, relation, object, author) do
      query_annotation(@connection, relation, author)
      |> where(
        [annotation: a, annotation_ref: ar],
        (ar.type_id == ^@subject and a.id == ^subject.id) or
          (ar.type_id == ^@object and a.id == ^object.id)
      )
      |> having([annotation_ref: ar], count(ar.id) == 2)
    end

    defp get(subject: subject, relation: relation, object: object, author: author) do
      query(subject, relation, object, author)
      |> Repo.one()
    end
  end
end
