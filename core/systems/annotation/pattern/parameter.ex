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
          statement: String.t() | nil,
          dimension: Ontology.ConceptModel.t() | nil,
          entity: Authentication.Entity.t() | nil
        }

  defstruct [:statement, :dimension, :entity]

  defimpl Systems.Annotation.Pattern do
    use Systems.Annotation.Pattern.Helpers

    @parameter "Parameter"

    def obtain(%{statement: nil}), do: raise(MissingFieldError, :statement)
    def obtain(%{dimension: nil}), do: raise(MissingFieldError, :dimension)
    def obtain(%{entity: nil}), do: raise(MissingFieldError, :entity)

    def obtain(%{
          statement: statement,
          dimension: dimension,
          entity: entity
        }) do
      if annotation = get(statement: statement, dimension: dimension, entity: entity) do
        {:ok, annotation}
      else
        type = obtain_concept!(@parameter, entity)
        annotation_ref = obtain_annotation_ref!(dimension)
        annotation = insert_annotation!(type, statement, entity, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{statement: statement, dimension: dimension, entity: entity}) do
      {:ok, query(statement, dimension, entity)}
    end

    defp query(statement, dimension, entity) do
      query_annotation(@parameter, statement, entity, dimension)
    end

    defp get(statement: statement, dimension: dimension, entity: entity) do
      query(statement, dimension, entity)
      |> Repo.one()
    end
  end
end
