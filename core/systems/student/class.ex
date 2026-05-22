defmodule Systems.Student.Class do
  @moduledoc """
    Defines study program using organisation nodes.
  """

  alias Frameworks.Utility.Identifier

  alias Systems.{
    Content,
    Org
  }

  def selector_labels([_ | _] = study_classes, locale, active_codes) do
    study_classes
    |> Enum.map(&selector_label(&1, locale, active_codes))
  end

  def selector_label(
        %Org.NodeModel{short_name_bundle: short_name_bundle} = class,
        locale,
        active_codes
      ) do
    text = Content.TextBundleModel.text(short_name_bundle, locale)
    code = code(class)
    %{id: code, value: text, active: active?(code, active_codes)}
  end

  def active?(code, active_codes)
      when is_binary(code) and is_list(active_codes) do
    Enum.member?(active_codes, code)
  end

  def active?(code, active_codes)
      when is_atom(code) and is_list(active_codes) do
    active?(Atom.to_string(code), active_codes)
  end

  def code(identifier), do: Frameworks.Utility.Identifier.to_string(identifier)

  def get_course(%{links: links, identifier: identifier}) do
    # Find linked org that is a course by checking identifier contains course-related patterns
    # (e.g. "rpr" for Research Participation Requirement courses)
    case Enum.find(links, &course?(&1)) do
      nil -> raise "No course found for class #{Identifier.to_string(identifier)}"
      course -> course
    end
  end

  defp course?(%{identifier: identifier}) when is_list(identifier) do
    # Course identifiers contain "rpr" (Research Participation Requirement)
    # or "course" for test/legacy data
    Enum.any?(identifier, &(&1 in ["rpr", "course"]))
  end

  defp course?(_), do: false
end
