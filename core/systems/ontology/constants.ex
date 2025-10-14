defmodule Systems.Ontology.Constants do
  @moduledoc """
  This module contains the Ontology constants.
  """

  @doc """
  Fundamental concept for creating a hierarchy of concepts.
  """
  defmacro subsumes, do: "Subsumes"

  @doc """
  Fundamental concept for creating a definition of a concept.
  """
  defmacro definition, do: "Definition"

  defmacro subject, do: "Subject"

  defmacro __using__(_) do
    quote do
      require Systems.Ontology.Constants
      alias Systems.Ontology.Constants

      @subsumes Constants.subsumes()
      @definition Constants.definition()
      @subject Constants.subject()
    end
  end
end
