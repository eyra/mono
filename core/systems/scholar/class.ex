defmodule Systems.Scholar.Class do
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
    case Enum.find(links, &(&1.type == :scholar_course)) do
      nil -> raise "No course found for class #{Identifier.to_string(identifier)}"
      course -> course
    end
  end

  def get_course(_class), do: raise("Could not find course for invalid class")
end
