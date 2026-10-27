defmodule Core.FeatureFlags do
  @moduledoc """
  Feature flags. Systems declare the flags they read (`c:Core.System.feature_flags/0`),
  the SaaS sets their defaults (`c:Core.SaaS.feature_flags/0`), and the app config
  (`config :core, :features`, and `ENABLED_APP_FEATURES` at runtime) has the final say.

  A declared flag is off unless the SaaS or the config turns it on; a flag that is
  neither declared nor configured is off. A configured name that no system declares
  stays in the effective list, with a warning at boot (`warn_undeclared/0`).
  """

  require Logger

  defmacro __using__(_opts \\ []) do
    quote do
      import Core.FeatureFlags, only: [feature_enabled?: 1, require_feature: 1]
    end
  end

  defmacro features_enabled?(feature_ids) when is_list(feature_ids) do
    unless __CALLER__.function do
      throw("Feature checking must be used from inside a function to allow i18n.")
    end

    quote bind_quoted: [feature_ids: feature_ids] do
      Enum.reduce(feature_ids, true, fn feature_id, acc ->
        acc and Core.FeatureFlags.conf_enabled?(feature_id)
      end)
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
    case Keyword.fetch(Core.Env.get(:features, []), feature_id) do
      {:ok, enabled?} -> enabled?
      :error -> Keyword.get(saas_defaults(), feature_id, false)
    end
  end

  @doc "The effective flags: the SaaS defaults of all declared flags, merged with the app config."
  def effective, do: effective(Core.Env.get(:features, []))

  @doc false
  def effective(config), do: saas_defaults() |> Keyword.merge(config) |> Enum.sort()

  @doc "Logs a warning for every configured flag name that no system declares."
  def warn_undeclared do
    for name <- undeclared(Core.Env.get(:features, [])) do
      Logger.warning("Feature flag #{inspect(name)} is configured, but no system declares it")
    end

    :ok
  end

  # `:""` is what an empty ENABLED_APP_FEATURES parses to (Core.RuntimeConfig.features/2).
  @doc false
  def undeclared(config) do
    declared = saas_defaults()

    config
    |> Keyword.keys()
    |> Enum.uniq()
    |> Enum.reject(&(&1 == :"" or Keyword.has_key?(declared, &1)))
  end

  # The SaaS is fixed at compile time, so its declared flags and defaults only
  # change with a new build; a dev server picks up a changed default on restart.
  defp saas_defaults do
    case :persistent_term.get(__MODULE__, nil) do
      nil ->
        defaults = Core.SaaS.feature_flags()
        :persistent_term.put(__MODULE__, defaults)
        defaults

      defaults ->
        defaults
    end
  end
end
