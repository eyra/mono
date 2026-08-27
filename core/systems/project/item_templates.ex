defmodule Systems.Project.ItemTemplates do
  @moduledoc false
  use Core.Enums.Base,
      {:project_item_templates, [:paper_screening, :benchmark_challenge, :data_donation, :questionnaire]}
end
