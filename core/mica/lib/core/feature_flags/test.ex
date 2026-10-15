defmodule Core.FeatureFlags.Test do
  defmacro __using__(_opts \\ []) do
    quote do
      setup do
        features = Application.get_env(:core, :features, [])

        on_exit(fn ->
          Application.put_env(:core, :features, features)
        end)
      end

      import Core.FeatureFlags.Test
    end
  end

  def set_feature_flag(feature, flag) do
    current_env = Application.get_env(:core, :features, [])

    Application.put_env(
      :core,
      :features,
      Keyword.put(current_env, feature, flag)
    )
  end
end
