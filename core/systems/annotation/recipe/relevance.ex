defmodule Systems.Annotation.Recipe.Relevance do
  @moduledoc """
  A recipe for creating a Relevance Annotation.
  A Relevance Annotation states the relevance between is relevant to a specific topic.
  """

  alias Systems.Account
  alias Systems.Annotation

  @type t :: %__MODULE__{
          relevance: :relevant | :irrelevant | :neutral,
          parameter: Annotation.Model.t() | nil,
          resource: Annotation.ResourceModel.t() | nil,
          author: Account.User.t() | nil
        }

  defstruct [:relevance, :parameter, :resource, :author, :superseded]

  defimpl Systems.Annotation.Recipe do
    use Systems.Annotation.Recipe.Helpers
    import Ecto.Query, warn: true

    @relevance "Relevance"
    @parameter "Parameter"
    @resource "Resource"

    def obtain(%{parameter: nil}), do: raise(MissingFieldError, :parameter)
    def obtain(%{resource: nil}), do: raise(MissingFieldError, :resource)
    def obtain(%{author: nil}), do: raise(MissingFieldError, :author)

    def obtain(%{
          relevance: relevance,
          parameter: parameter,
          resource: resource,
          author: author
        }) do
      if annotation =
           get(relevance: relevance, parameter: parameter, resource: resource, author: author) do
        {:ok, annotation}
      else
        type = obtain_concept!(@relevance, author)
        parameter_ref = obtain_annotation_ref!({:concept, {@parameter, parameter}}, author)
        resource_ref = obtain_annotation_ref!({:resource, {@resource, resource}}, author)

        annotation =
          insert_annotation!(
            type,
            to_statement(relevance),
            author,
            [parameter_ref, resource_ref],
            []
          )

        {:ok, annotation}
      end
    end

    def query(%{relevance: relevance, parameter: parameter, resource: resource, author: author}) do
      {:ok, query(relevance, parameter, resource, author)}
    end

    defp query(relevance, parameter, resource, author) do
      query_annotation(@relevance, to_statement(relevance), author)
      |> where(
        [annotation: a, annotation_ref: ar],
        (ar.type_id == ^@parameter and a.id == ^parameter.id) or
          (ar.type_id == ^@resource and a.id == ^resource.id)
      )
      |> having([annotation_ref: ar], count(ar.id) == 2)
    end

    defp get(relevance: relevance, parameter: parameter, resource: resource, author: author) do
      query(relevance, parameter, resource, author)
      |> Repo.one()
    end

    defp to_statement(relevance) do
      case relevance do
        :relevant -> "Relevant"
        :irrelevant -> "Irrelevant"
        :neutral -> "Neutral"
      end
    end
  end
end
