defmodule Core.FeatureFlagsTest do
  use Core.DataCase, async: true
  alias Core.FeatureFlags

  describe "feature_enabled?/1" do
    test "return true by default" do
      assert FeatureFlags.feature_enabled?(:some_unconfigured_flag)
    end

    test "allow configuration via the application env" do
      current_env = Application.get_env(:core, :features, [])

      Application.put_env(
        :core,
        :features,
        Keyword.put(current_env, :a_feature_used_by_this_test, false)
      )

      refute FeatureFlags.feature_enabled?(:a_feature_used_by_this_test)
    end
  end
end
