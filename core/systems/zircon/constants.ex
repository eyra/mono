defmodule Systems.Zircon.Constants do
  @moduledoc """
  This module contains the Zircon constants.
  """

  @doc """
  A research framework is a set of research dimensions that are used to define the scope of a research study.
  """
  defmacro research_framework, do: "Research Framework"

  @doc """
  A research dimension is a concept used to define dimensions used in a research framework.
  """
  defmacro research_dimension, do: "Research Dimension"

  @doc """
  A research parameter is a concept used to define parameters for a research dimension.
  """
  defmacro research_parameter, do: "Research Parameter"

  @doc """
  Default criteria for a screening tool.
  """
  defmacro criteria_dimensions, do: ["Population", "Intervention", "Comparison", "Outcome"]

  defmacro __using__(_) do
    quote do
      require Systems.Zircon.Constants
      alias Systems.Zircon.Constants

      @research_framework Constants.research_framework()
      @research_dimension Constants.research_dimension()
      @research_parameter Constants.research_parameter()
      @criteria_dimensions Constants.criteria_dimensions()
    end
  end
end
