defmodule Core.FeatureFlags.Test do
  defmacro __using__(_opts \\ []) do
    quote do
      setup do
        features = Core.Env.get(:features, [])

        on_exit(fn ->
          Core.Env.put(:features, features)
        end)
      end

      import Core.FeatureFlags.Test
    end
  end

  def set_feature_flag(feature, flag) do
    current_env = Core.Env.get(:features, [])

    Core.Env.put(
      :features,
      Keyword.put(current_env, feature, flag)
    )
  end
end
