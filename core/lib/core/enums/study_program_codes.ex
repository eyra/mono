defmodule Core.Enums.StudyProgramCodes do
  @moduledoc """
    Defines study program codes used as user feature for vu students.
  """
  use Core.Enums.Base,
      {:study_pogram_codes, [:bk_1, :bk_1_h, :bk_2, :bk_2_h, :iba_1, :iba_1_h, :iba_2, :iba_2_h]}
end
