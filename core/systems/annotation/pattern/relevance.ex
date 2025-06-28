defmodule Systems.Annotation.Pattern.Relevance do
  @moduledoc """
  A pattern for creating a Relevance Annotation.
  A Relevance Annotation states the relevance between is relevant to a specific topic.
  """

  alias Core.Authentication
  alias Systems.Annotation

  @type t :: %__MODULE__{
          relevance: :relevant | :irrelevant | :neutral,
          parameter: Annotation.Model.t() | nil,
          resource: Annotation.ResourceModel.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:relevance, :parameter, :resource, :entity, :superseded]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers
    import Ecto.Query, warn: true

    @relevance "Relevance"
    @parameter "Parameter"
    @resource "Resource"

    def obtain(%{parameter: nil}), do: raise(MissingFieldError, :parameter)
    def obtain(%{resource: nil}), do: raise(MissingFieldError, :resource)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          relevance: relevance,
          parameter: parameter,
          resource: resource,
          entity: entity
        }) do
      if annotation =
           get(relevance: relevance, parameter: parameter, resource: resource, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@relevance, entity)
        parameter_ref = obtain_annotation_ref!({:concept, {@parameter, parameter}}, entity)
        resource_ref = obtain_annotation_ref!({:resource, {@resource, resource}}, entity)

        annotation =
          insert_annotation!(
            type,
            to_statement(relevance),
            entity,
            [parameter_ref, resource_ref],
            []
          )

        {:ok, annotation}
      end
    end

    def query(%{relevance: relevance, parameter: parameter, resource: resource, entity: entity}) do
      {:ok, query(relevance, parameter, resource, entity)}
    end

    defp query(relevance, parameter, resource, entity) do
      query_annotation(@relevance, to_statement(relevance), entity)
      |> where(
        [annotation: a, annotation_ref: ar],
        (ar.type_id == ^@parameter and a.id == ^parameter.id) or
          (ar.type_id == ^@resource and a.id == ^resource.id)
      )
      |> having([annotation_ref: ar], count(ar.id) == 2)
    end

    defp get(relevance: relevance, parameter: parameter, resource: resource, entity: entity) do
      query(relevance, parameter, resource, entity)
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
