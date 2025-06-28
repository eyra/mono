defmodule Systems.Onyx.SeedBase do
  @moduledoc """
  Base macros and functions for seeding ontology concepts and annotations.

  Provides common macros for creating concepts, annotations, and relationships
  used across different seed modules with a clean DSL.
  """

  import Systems.Ontology.Public

  use Systems.Ontology.Constants
  use Systems.Annotation.Constants

  alias Systems.Annotation
  alias Systems.Onyx

  @doc """
  Macro for annotating a concept with a definition.
  """
  defmacro annotate_definition(concept, definition, entity) do
    quote do
      {:ok, _annotation} =
        %Annotation.Pattern.Definition{
          definition: unquote(definition),
          subject: unquote(concept),
          entity: unquote(entity)
        }
        |> Annotation.Pattern.obtain()

      unquote(concept)
    end
  end

  @doc """
  Macro for defining a concept with a phrase and text description.
  """
  defmacro defconcept(phrase, text, entity) do
    quote do
      concept = obtain_concept!(unquote(phrase), unquote(entity))
      annotate_definition(concept, unquote(text), unquote(entity))
    end
  end

  @doc """
  Macro for defining multiple concepts from a keyword list.
  """
  defmacro defconcepts(keyword_list, entity) do
    quote do
      Enum.map(unquote(keyword_list), fn {atom, text} ->
        phrase =
          atom
          |> Atom.to_string()
          |> Onyx.SeedBase.format_concept_name()

        defconcept(phrase, text, unquote(entity))
      end)
    end
  end

  @doc """
  Macro for categorizing subjects under an object using the subsumes predicate.
  """
  defmacro defcategory(subjects, object, subsumes, entity) do
    quote do
      Enum.each(unquote(subjects), fn subject ->
        obtain_predicate(subject, unquote(subsumes), unquote(object), unquote(entity))
      end)

      %{
        category: unquote(object),
        members: unquote(subjects)
      }
    end
  end

  @doc """
  Macro for defining a type concept (alias for defconcept).
  """
  defmacro deftype(phrase, text, entity) do
    quote do
      defconcept(unquote(phrase), unquote(text), unquote(entity))
    end
  end

  @doc """
  Formats concept names by capitalizing words if no capital letters are present.
  """
  def format_concept_name(name) do
    if contains_capital_letter?(name) do
      name
    else
      name
      |> String.split(" ")
      |> Enum.map_join(" ", &String.capitalize/1)
    end
  end

  defp contains_capital_letter?(name) do
    String.match?(name, ~r/[A-Z]/)
  end
end
