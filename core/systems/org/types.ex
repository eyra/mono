defmodule Systems.Org.Types do
  @moduledoc """
    Defines types of organisations.
  """
  use Core.Enums.Base,
      {:organisation_types,
       [
         :company,
         :department,
         :university,
         :faculty,
         :student_program,
         :student_class,
         :student_course
       ]}

  def filter(organisations, nil), do: organisations
  def filter(organisations, []), do: organisations

  def filter(organisations, filters) do
    organisations |> Enum.filter(&(&1.type in filters))
  end
end
