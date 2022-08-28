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
         :scholar_program,
         :scholar_class,
         :scholar_course
       ]}
end
