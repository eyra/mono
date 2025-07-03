defmodule Systems.Assignment.TemplateFlagsTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Systems.Assignment.Template.Flags

  describe "Template.Flags with opt_in behavior" do
    test "new/0 creates struct with all flags disabled by default" do
      flags = Flags.Settings.new()

      # All flags should be false by default (opt-in behavior)
      assert flags.expected == false
      assert flags.language == false
      assert flags.branding == false
      assert flags.information == false
      assert flags.privacy == false
      assert flags.consent == false
      assert flags.helpdesk == false
      assert flags.affiliate == false
    end

    test "new/1 with opt_in enables specified flags only" do
      flags = Flags.Settings.new(opt_in: [:language, :branding])

      # Only specified flags should be enabled
      assert flags.language == true
      assert flags.branding == true

      # All other flags should remain disabled
      assert flags.expected == false
      assert flags.information == false
      assert flags.privacy == false
      assert flags.consent == false
      assert flags.helpdesk == false
      assert flags.affiliate == false
    end

    test "new/1 with empty opt_in list keeps all flags disabled" do
      flags = Flags.Settings.new(opt_in: [])

      # All flags should remain false
      assert flags.expected == false
      assert flags.language == false
      assert flags.branding == false
      assert flags.information == false
      assert flags.privacy == false
      assert flags.consent == false
      assert flags.helpdesk == false
      assert flags.affiliate == false
    end

    test "new/1 with all flags in opt_in enables all flags" do
      all_flags = [
        :expected,
        :language,
        :branding,
        :information,
        :privacy,
        :consent,
        :helpdesk,
        :affiliate
      ]

      flags = Flags.Settings.new(opt_in: all_flags)

      # All flags should be enabled
      assert flags.expected == true
      assert flags.language == true
      assert flags.branding == true
      assert flags.information == true
      assert flags.privacy == true
      assert flags.consent == true
      assert flags.helpdesk == true
      assert flags.affiliate == true
    end

    test "works with Participants flags" do
      flags = Flags.Participants.new(opt_in: [:invite_participants])

      assert flags.invite_participants == true
      assert flags.advert_in_pool == false
      assert flags.affiliate == false
    end

    test "works with Workflow flags" do
      flags = Flags.Workflow.new()

      # All flags disabled by default
      assert flags.library == false

      flags_with_opt_in = Flags.Workflow.new(opt_in: [:library])
      assert flags_with_opt_in.library == true
    end

    test "works with Monitor flags" do
      flags = Flags.Monitor.new()

      # All flags disabled by default
      assert flags.consent == false

      flags_with_opt_in = Flags.Monitor.new(opt_in: [:consent])
      assert flags_with_opt_in.consent == true
    end

    test "works with flags modules that have no flags defined" do
      import_flags = Flags.Import.new()
      assert import_flags == %Flags.Import{}

      criteria_flags = Flags.Criteria.new()
      assert criteria_flags == %Flags.Criteria{}

      affiliate_flags = Flags.Affiliate.new()
      assert affiliate_flags == %Flags.Affiliate{}
    end
  end

  describe "backward compatibility during transition" do
    test "ignores opt_out parameter when opt_in is provided" do
      # During transition, if both are provided, opt_in should take precedence
      flags = Flags.Settings.new(opt_in: [:language], opt_out: [:branding])

      assert flags.language == true
      # Should be false due to opt_in behavior, not opt_out
      assert flags.branding == false
    end

    test "handles non-existent flags gracefully" do
      # Should not crash if opt_in contains flags that don't exist
      flags = Flags.Settings.new(opt_in: [:language, :non_existent_flag])

      assert flags.language == true
      # Other flags should remain false
      assert flags.branding == false
    end
  end

  describe "Access behavior for backward compatibility" do
    test "supports bracket notation access" do
      flags = Flags.Settings.new(opt_in: [:language, :branding])

      # Should work with bracket notation like a map
      assert flags[:language] == true
      assert flags[:branding] == true
      assert flags[:expected] == false
      assert flags[:privacy] == false
    end

    test "supports Access.get/2" do
      flags = Flags.Participants.new(opt_in: [:invite_participants])

      assert Access.get(flags, :invite_participants) == true
      assert Access.get(flags, :advert_in_pool) == false
      assert Access.get(flags, :affiliate) == false
    end

    test "supports get_in for nested access" do
      flags = Flags.Settings.new(opt_in: [:language])

      # This mimics how it might be used in templates
      assert get_in(flags, [:language]) == true
      assert get_in(flags, [:branding]) == false
    end

    test "returns nil for non-existent keys" do
      flags = Flags.Settings.new()

      assert flags[:non_existent] == nil
      assert Access.get(flags, :non_existent) == nil
    end
  end

  describe "Backwards compatibility with deprecation warnings" do
    test "opt_out still works but shows deprecation warning" do
      # Capture the warning
      warning_output =
        capture_io(:stderr, fn ->
          flags = Flags.Settings.new(opt_out: [:language, :branding])

          # Should work like old opt_out behavior
          # was in opt_out, so false
          assert flags.language == false
          # was in opt_out, so false
          assert flags.branding == false
          # was NOT in opt_out, so true
          assert flags.expected == true
          # was NOT in opt_out, so true
          assert flags.information == true
        end)

      # Should contain deprecation warning
      assert warning_output =~ ":opt_out is deprecated"
      assert warning_output =~ "use :opt_in instead"
    end

    test "both opt_in and opt_out provided - opt_in takes precedence with warning" do
      warning_output =
        capture_io(:stderr, fn ->
          flags = Flags.Settings.new(opt_in: [:language], opt_out: [:branding])

          # opt_in should take precedence, opt_out should be ignored
          assert flags.language == true
          # not in opt_in, so false
          assert flags.branding == false
        end)

      # Should show warning since opt_out is deprecated
      assert warning_output =~ ":opt_out is deprecated"
      assert warning_output =~ "use :opt_in instead"
    end

    test "flags/0 function returns available flags" do
      assert is_list(Flags.Settings.flags())
      assert :language in Flags.Settings.flags()
      assert :branding in Flags.Settings.flags()
      assert :expected in Flags.Settings.flags()

      # Test other flag modules
      assert :library in Flags.Workflow.flags()
      assert :consent in Flags.Monitor.flags()

      # Empty flag modules should return empty list
      assert Flags.Import.flags() == []
      assert Flags.Criteria.flags() == []
      assert Flags.Affiliate.flags() == []
    end
  end

  describe "Default behavior tests" do
    test "new/0 without arguments sets all flags to false" do
      settings_flags = Flags.Settings.new()
      assert settings_flags.expected == false
      assert settings_flags.language == false
      assert settings_flags.branding == false
      assert settings_flags.information == false
      assert settings_flags.privacy == false
      assert settings_flags.consent == false
      assert settings_flags.helpdesk == false
      assert settings_flags.affiliate == false

      # Test other modules too
      participants_flags = Flags.Participants.new()
      assert participants_flags.advert_in_pool == false
      assert participants_flags.invite_participants == false
      assert participants_flags.affiliate == false

      workflow_flags = Flags.Workflow.new()
      assert workflow_flags.library == false

      monitor_flags = Flags.Monitor.new()
      assert monitor_flags.consent == false
    end

    test "new/1 with empty opt_in behaves same as new/0" do
      flags1 = Flags.Settings.new()
      flags2 = Flags.Settings.new(opt_in: [])

      # Should be identical
      assert flags1 == flags2
    end

    test "new/1 with subset of flags enables only specified ones" do
      flags = Flags.Settings.new(opt_in: [:language, :privacy])

      # Only specified flags should be true
      assert flags.language == true
      assert flags.privacy == true

      # All others should be false
      assert flags.expected == false
      assert flags.branding == false
      assert flags.information == false
      assert flags.consent == false
      assert flags.helpdesk == false
      assert flags.affiliate == false
    end

    test "new/1 with all flags enables everything" do
      all_settings_flags = [
        :expected,
        :language,
        :branding,
        :information,
        :privacy,
        :consent,
        :helpdesk,
        :affiliate
      ]

      flags = Flags.Settings.new(opt_in: all_settings_flags)

      # All should be true
      assert flags.expected == true
      assert flags.language == true
      assert flags.branding == true
      assert flags.information == true
      assert flags.privacy == true
      assert flags.consent == true
      assert flags.helpdesk == true
      assert flags.affiliate == true
    end
  end
end
