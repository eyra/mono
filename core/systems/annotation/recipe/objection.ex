defmodule Systems.Annotation.Recipe.Objection do
  @moduledoc """
  A recipe for creating a Objection Annotation.
  An Objection is a negative vote in the context of a Sociocratic consent-based decision making round.
  """

  alias Systems.Account
  alias Systems.Ontology

  alias Systems.Account
  alias Systems.Ontology

  @type t :: %__MODULE__{
          reason: String.t() | nil,
          subject: Ontology.ConceptModel.t() | nil,
          author: Account.User.t() | nil
        }

  defstruct [:reason, :subject, :author]

  defimpl Systems.Annotation.Recipe do
    use Systems.Annotation.Recipe.Helpers

    @objection "Objection"
    @subject "Subject"

    def obtain(%{reason: nil}), do: raise(MissingFieldError, :reason)
    def obtain(%{subject: nil}), do: raise(MissingFieldError, :subject)
    def obtain(%{author: nil}), do: raise(MissingFieldError, :author)

    def obtain(%{
          reason: reason,
          subject: subject,
          author: author
        }) do
      if annotation = get(reason: reason, subject: subject, author: author) do
        {:ok, annotation}
      else
        type = obtain_concept!(@objection, author)
        annotation_ref = obtain_annotation_ref!({:concept, {@subject, subject}}, author)
        annotation = insert_annotation!(type, reason, author, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{reason: reason, subject: subject, author: author}) do
      {:ok, query(reason, subject, author)}
    end

    defp query(reason, subject, author) do
      query_annotation(@objection, reason, author, {:concept, {@subject, subject}})
    end

    defp get(reason: reason, subject: subject, author: author) do
      query(reason, subject, author)
      |> Repo.one()
    end
  end
end
