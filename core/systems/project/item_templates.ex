defmodule Systems.Project.ItemTemplates do
  use Core.Enums.Base,
      {:project_item_templates,
       [:paper_screening, :benchmark_challenge, :data_donation, :questionnaire]}
end
