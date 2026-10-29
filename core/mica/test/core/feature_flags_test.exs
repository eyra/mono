defmodule Core.FeatureFlagsTest do
  use Core.DataCase, async: false
  use Core.FeatureFlags
  use Core.FeatureFlags.Test

  describe "feature_enabled?/1" do
    test "return false for a flag that is neither declared nor configured" do
      refute feature_enabled?(:some_unconfigured_flag)
    end

    test "return the SaaS default of a declared flag that is not configured" do
      Core.Env.put(:features, [])

      assert feature_enabled?(:password_sign_in)
      refute feature_enabled?(:probe)
    end

    test "allow configuration via the application env" do
      set_feature_flag(:password_sign_in, false)
      set_feature_flag(:a_feature_used_by_this_test, true)

      refute feature_enabled?(:password_sign_in)
      assert feature_enabled?(:a_feature_used_by_this_test)
    end
  end

  describe "require_feature/1" do
    test "do nothing when feature is enabled" do
      set_feature_flag(:a_feature_used_by_this_test, true)
      require_feature(:a_feature_used_by_this_test)
    end

    test "throw when feature is not configured" do
      assert catch_throw(require_feature(:some_unconfigured_flag)) ==
               "Feature: some_unconfigured_flag is required"
    end

    test "throw when feature is disabled" do
      set_feature_flag(:a_feature_used_by_this_test, false)

      assert catch_throw(require_feature(:a_feature_used_by_this_test)) ==
               "Feature: a_feature_used_by_this_test is required"
    end
  end

  describe "effective/0" do
    test "lists every declared flag with its SaaS default, merged with the config" do
      Core.Env.put(:features, otp: true, debug: true)

      assert Core.FeatureFlags.effective() ==
               Core.SaaS.feature_flags()
               |> Keyword.merge(otp: true, debug: true)
               |> Enum.sort()
    end
  end

  describe "undeclared/1" do
    test "names a configured flag that no system declares" do
      assert Core.FeatureFlags.undeclared(debug: true) == [:debug]
    end

    test "leaves out declared flags" do
      assert Core.FeatureFlags.undeclared(otp: true, password_sign_in: false) == []
    end

    test "names a flag configured twice once" do
      assert Core.FeatureFlags.undeclared(debug: true, debug: false) == [:debug]
    end

    test "leaves out the empty name of an empty ENABLED_APP_FEATURES" do
      assert Core.FeatureFlags.undeclared("": true) == []
    end
  end
end
