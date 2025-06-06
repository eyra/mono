defmodule Systems.Annotation.Recipe.Consent do
  @moduledoc """
  A recipe for creating a Consent Annotation.
  A Consent is a positive vote in the context of a Sociocratic consent-based decision making round.
  """

  alias Systems.Account
  alias Systems.Ontology

  alias Systems.Account
  alias Systems.Ontology

  @type t :: %__MODULE__{
          subject: Ontology.ConceptModel.t() | nil,
          author: Account.User.t() | nil
        }

  defstruct [:subject, :author]

  defimpl Systems.Annotation.Recipe do
    use Systems.Annotation.Recipe.Helpers

    @consent "Consent"
    @subject "Subject"

    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{author: nil}), do: raise(MissingFieldError, :author)

    def obtain(%{
          subject: subject,
          author: author
        }) do
      if annotation = get(subject: subject, author: author) do
        {:ok, annotation}
      else
        type = obtain_concept!(@consent, author)
        annotation_ref = obtain_annotation_ref!({:concept, {@subject, subject}}, author)
        annotation = insert_annotation!(type, @consent, author, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{subject: subject, author: author}) do
      {:ok, query(subject, author)}
    end

    defp query(subject, author) do
      query_annotation(@consent, @consent, author, {:concept, {@subject, subject}})
    end

    defp get(subject: subject, author: author) do
      query(subject, author)
      |> Repo.one()
    end
  end
end
