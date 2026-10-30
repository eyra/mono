defmodule Next.Systems.Annotation.Constants do
  @moduledoc """
  This module contains the Annotation constants.
  """

  @doc """
  Fundamental `annotation type` for creating a definition of a concept.
  """
  defmacro definition, do: "Definition"

  @doc """
  Fundamental `annotation reference type` for the main subject of an annotation.
  """
  defmacro subject, do: "Subject"

  defmacro __using__(_) do
    quote do
      require Next.Systems.Ontology.Constants
      alias Next.Systems.Ontology.Constants

      @definition Constants.definition()
      @subject Constants.subject()
    end
  end
end
