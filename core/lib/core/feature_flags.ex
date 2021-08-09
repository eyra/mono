defmodule Core.FeatureFlags do
  def feature_enabled?(feature_id) when is_atom(feature_id) do
    Application.get_env(:core, :features, [])
    |> Keyword.get(feature_id, true)
  end
end
