defmodule Systems.Scholar.Class do
  @moduledoc """
    Defines study program using organisation nodes.
  """

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
      when is_atom(code) and is_list(active_codes) do
    Enum.member?(active_codes, code)
  end

  # Backwards compatible from old code format to new organisation node identifier (intentionally ugly code)
  def identifier(:bk_1), do: ["vu", "sbe", "bk", ":year1", ":2021"]
  def identifier(:bk_1_h), do: ["vu", "sbe", "bk", ":year1", ":resit", ":2021"]
  def identifier(:bk_2), do: ["vu", "sbe", "bk", ":year2", ":2021"]
  def identifier(:bk_2_h), do: ["vu", "sbe", "bk", ":year2", ":resit", ":2021"]
  def identifier(:iba_1), do: ["vu", "sbe", "iba", ":year1", ":2021"]
  def identifier(:iba_1_h), do: ["vu", "sbe", "iba", ":year1", ":resit", ":2021"]
  def identifier(:iba_2), do: ["vu", "sbe", "iba", ":year2", ":2021"]
  def identifier(:iba_2_h), do: ["vu", "sbe", "iba", ":year2", ":resit", ":2021"]
  def identifier(code), do: raise("Unsupported study class code #{code}")

  def code(%Org.NodeModel{identifier: identifier}), do: code(identifier)
  def code(["vu", "sbe", "bk", ":year1", ":2021"]), do: :bk_1
  def code(["vu", "sbe", "bk", ":year1", ":resit", ":2021"]), do: :bk_1_h
  def code(["vu", "sbe", "bk", ":year2", ":2021"]), do: :bk_2
  def code(["vu", "sbe", "bk", ":year2", ":resit", ":2021"]), do: :bk_2_h
  def code(["vu", "sbe", "iba", ":year1", ":2021"]), do: :iba_1
  def code(["vu", "sbe", "iba", ":year1", ":resit", ":2021"]), do: :iba_1_h
  def code(["vu", "sbe", "iba", ":year2", ":2021"]), do: :iba_2
  def code(["vu", "sbe", "iba", ":year2", ":resit", ":2021"]), do: :iba_2_h
  def code(identifier), do: raise("Unsupported org node identifier #{identifier}")
end
