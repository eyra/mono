defmodule Systems.Advert.SelectorLabels do
  @moduledoc """
  Builds selector option labels for pools using the director's inclusion criteria.
  Extracted from SubmissionView to improve separation of concerns and reduce code complexity.
  """

  alias Frameworks.Concept.Directable
  alias Systems.Pool

  @enum_map %{
    genders: Core.Enums.Genders,
    native_languages: Core.Enums.NativeLanguages
  }

  @doc """
  Return a map of selector field => labels for the given pool and criteria.
  """
  def selector_option_labels(pool, criteria) do
    Directable.director(pool).inclusion_criteria()
    |> Enum.map(&get_selector_labels(&1, criteria))
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  # birth_years does not have labels as it is not a selector
  defp get_selector_labels(:birth_years, %Pool.CriteriaModel{}), do: nil

  defp get_selector_labels(field, %Pool.CriteriaModel{} = criteria) when is_atom(field) do
    case Map.get(@enum_map, field) do
      nil -> nil
      enum_module -> {field, enum_module.labels(Map.get(criteria, field))}
    end
  end
end
