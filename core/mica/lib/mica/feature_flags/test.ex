defmodule Mica.FeatureFlags.Test do
  defmacro __using__(_opts \\ []) do
    quote do
      setup do
        features = Mica.Env.get(:features, [])

        on_exit(fn ->
          Mica.Env.put(:features, features)
        end)
      end

      import Mica.FeatureFlags.Test
    end
  end

  def set_feature_flag(feature, flag) do
    current_env = Mica.Env.get(:features, [])

    Mica.Env.put(
      :features,
      Keyword.put(current_env, feature, flag)
    )
  end
end
