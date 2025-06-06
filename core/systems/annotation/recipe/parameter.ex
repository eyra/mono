defmodule Systems.Annotation.Recipe.Parameter do
  @moduledoc """
  A recipe for creating a Parameter Annotation.

  A Parameter is a quantifiable or descriptive characteristic, value, or condition that specifies
  or defines a particular aspect of a Dimension within a scientific system, process, model, or
  phenomenon under investigation. Parameters serve as inputs, constants, or variables that
  characterize or influence a Dimension, enabling the description, measurement, manipulation, or
  control of relationships, behaviors, or outcomes in a scientific study.
  """

  alias Systems.Account
  alias Systems.Ontology

  @type t :: %__MODULE__{
          parameter: String.t() | nil,
          dimension: Ontology.ConceptModel.t() | nil,
          author: Account.User.t() | nil
        }

  defstruct [:parameter, :dimension, :author]

  defimpl Systems.Annotation.Recipe do
    use Systems.Annotation.Recipe.Helpers

    @dimension "Dimension"
    @parameter "Parameter"

    def obtain(%{parameter: nil}), do: raise(MissingFieldError, :parameter)
    def obtain(%{dimension: nil}), do: raise(MissingFieldError, :dimension)
    def obtain(%{author: nil}), do: raise(MissingFieldError, :author)

    def obtain(%{
          parameter: parameter,
          dimension: dimension,
          author: author
        }) do
      if annotation = get(parameter: parameter, dimension: dimension, author: author) do
        {:ok, annotation}
      else
        type = obtain_concept!(@parameter, author)
        annotation_ref = obtain_annotation_ref!({:concept, {@dimension, dimension}}, author)
        annotation = insert_annotation!(type, parameter, author, [annotation_ref], [])
        {:ok, annotation}
      end
    end

    def query(%{parameter: parameter, dimension: dimension, author: author}) do
      {:ok, query(parameter, dimension, author)}
    end

    defp query(parameter, dimension, author) do
      query_annotation(@parameter, parameter, author, {:concept, {@dimension, dimension}})
    end

    defp get(parameter: parameter, dimension: dimension, author: author) do
      query(parameter, dimension, author)
      |> Repo.one()
    end
  end
end
