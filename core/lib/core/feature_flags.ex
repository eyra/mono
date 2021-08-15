defmodule Core.FeatureFlags do
  defmacro __using__(_opts \\ []) do
    quote do
      import Core.FeatureFlags, only: [feature_enabled?: 1, require_feature: 1]
    end
  end

  defmacro feature_enabled?(feature_id) when is_atom(feature_id) do
    unless __CALLER__.function do
      throw("Feature checking must be used from inside a function to allow i18n.")
    end

    quote bind_quoted: [feature_id: feature_id] do
      Core.FeatureFlags.conf_enabled?(feature_id)
    end
  end

  defmacro require_feature(feature_id) when is_atom(feature_id) do
    quote do
      unless Core.FeatureFlags.feature_enabled?(unquote(feature_id)) do
        throw("Feature: #{unquote(feature_id)} is required")
      end
    end
  end

  def conf_enabled?(feature_id) do
    Application.get_env(:core, :features, [])
    |> Keyword.get(feature_id, true)
  end
end
