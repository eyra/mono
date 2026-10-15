defmodule Core.FeatureFlagsTest do
  use Core.DataCase, async: false
  use Core.FeatureFlags
  use Core.FeatureFlags.Test

  describe "feature_enabled?/1" do
    test "return true by default" do
      assert feature_enabled?(:some_unconfigured_flag)
    end

    test "allow configuration via the application env" do
      current_env = Application.get_env(:core, :features, [])

      Application.put_env(
        :core,
        :features,
        Keyword.put(current_env, :a_feature_used_by_this_test, false)
      )

      refute feature_enabled?(:a_feature_used_by_this_test)
    end
  end

  describe "require_feature/1" do
    test "do nothing when feature is enabled" do
      require_feature(:some_unconfigured_flag)
    end

    test "throw when feature is disabled" do
      current_env = Application.get_env(:core, :features, [])

      Application.put_env(
        :core,
        :features,
        Keyword.put(current_env, :a_feature_used_by_this_test, false)
      )

      assert catch_throw(require_feature(:a_feature_used_by_this_test)) ==
               "Feature: a_feature_used_by_this_test is required"
    end
  end
end
