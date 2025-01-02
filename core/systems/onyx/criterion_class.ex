defmodule Systems.Onyx.CriterionClass do
  use Core.Enums.Base,
      {:onyx_criterion_class, [:study_type, :population, :intervention, :comparison, :outcome]}
end
