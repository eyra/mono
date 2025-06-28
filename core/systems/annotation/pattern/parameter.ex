defmodule Systems.Annotation.Pattern.Parameter do
  @moduledoc """
  A pattern for creating a Parameter Annotation.

  A Parameter is a quantifiable or descriptive characteristic, value, or condition that specifies
  or defines a particular aspect of a Dimension within a scientific system, process, model, or
  phenomenon under investigation. Parameters serve as inputs, constants, or variables that
  characterize or influence a Dimension, enabling the description, measurement, manipulation, or
  control of relationships, behaviors, or outcomes in a scientific study.
  """

  alias Core.Authentication
  alias Systems.Ontology

  @type t :: %__MODULE__{
          parameter: String.t() | nil,
          dimension: Ontology.ConceptModel.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:parameter, :dimension, :entity]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers

    @dimension "Dimension"
    @parameter "Parameter"

    def obtain(%{parameter: nil}), do: raise(MissingFieldError, :parameter)
    def obtain(%{dimension: nil}), do: raise(MissingFieldError, :dimension)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          parameter: parameter,
          dimension: dimension,
          entity: entity
        }) do
      if annotation = get(parameter: parameter, dimension: dimension, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@parameter, entity)
        annotation_ref = obtain_annotation_ref!({:concept, {@dimension, dimension}}, entity)
        annotation = insert_annotation!(type, parameter, entity, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{parameter: parameter, dimension: dimension, entity: entity}) do
      {:ok, query(parameter, dimension, entity)}
    end

    defp query(parameter, dimension, entity) do
      query_annotation(@parameter, parameter, entity, {:concept, {@dimension, dimension}})
    end

    defp get(parameter: parameter, dimension: dimension, entity: entity) do
      query(parameter, dimension, entity)
      |> Repo.one()
    end
  end
end
