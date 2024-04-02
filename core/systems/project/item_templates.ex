defmodule Systems.Project.ItemTemplates do
  if Application.compile_env(:core, :leaderboard_enabled) do
    use Core.Enums.Base,
        {:project_item_templates, [:benchmark_challenge, :data_donation, :leaderboard]}
  else
    use Core.Enums.Base, {:project_item_templates, [:benchmark_challenge, :data_donation]}
  end
end
