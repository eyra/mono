defmodule Systems.Annotation.Pattern.Relevance do
  @moduledoc """
  A pattern for creating a Relevance Annotation.
  A Relevance Annotation states the relevance between a parameter and a resource.
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
        sub_type = obtain_concept!(to_sub_type_phrase(relevance), entity)

        sub_type_ref = obtain_annotation_ref!(sub_type)
        parameter_ref = obtain_annotation_ref!(parameter)
        resource_ref = obtain_annotation_ref!(resource)

        annotation =
          insert_annotation!(
            type,
            to_statement(relevance, parameter),
            entity,
            [sub_type_ref, parameter_ref, resource_ref],
            []
          )

        {:ok, annotation}
      end
    end

    def query(%{relevance: relevance, parameter: parameter, resource: resource, entity: entity}) do
      {:ok, query(relevance, parameter, resource, entity)}
    end

    defp query(relevance, parameter, resource, entity) do
      query_annotation(@relevance, to_statement(relevance, parameter), entity)
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

    defp to_statement(relevance, %Annotation.Model{} = parameter) do
      case relevance do
        :relevant ->
          "I find '#{parameter.statement}' relevant for this resource"

        :irrelevant ->
          "I find '#{parameter.statement}' irrelevant for this resource"

        :neutral ->
          "I'm not sure about the relevance of '#{parameter.statement}' for this resource"
      end
    end

    defp to_sub_type_phrase(relevance) do
      relevance
      |> Atom.to_string()
      |> String.split("_")
      |> Enum.reject(&(&1 == ""))
      |> Enum.map_join(" ", &String.capitalize(&1))
    end
  end
end
