defmodule Systems.Annotation.Recipe.Definition do
  alias Systems.Account
  alias Systems.Ontology

  @type t :: %__MODULE__{
          definition: String.t() | nil,
          subject: Ontology.ConceptModel.t() | nil,
          author: Account.User.t() | nil
        }

  defstruct [:definition, :subject, :author]

  defimpl Systems.Annotation.Recipe do
    use Systems.Annotation.Recipe.Helpers

    def obtain(%{definition: nil}), do: raise(MissingFieldError, :definition)
    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{author: nil}), do: raise(MissingFieldError, :author)

    def obtain(%{
          definition: definition,
          subject: subject,
          author: author
        }) do
      if annotation = get(definition: definition, subject: subject, author: author) do
        {:ok, annotation}
      else
        type = obtain_concept!(@definition, author)
        annotation_ref = obtain_annotation_ref!({:concept, {@subject, subject}}, author)
        annotation = insert_annotation!(type, definition, author, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{definition: definition, subject: subject, author: author}) do
      {:ok, query(definition, subject, author)}
    end

    defp query(definition, subject, author) do
      query_annotation(@definition, definition, author, {:concept, {@subject, subject}})
    end

    defp get(definition: definition, subject: subject, author: author) do
      query(definition, subject, author)
      |> Repo.one()
    end
  end
end
