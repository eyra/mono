defmodule Systems.Assignment.TemplateMigrationTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Systems.Assignment.Template.Flags

  alias Systems.Assignment.{
    TemplateBenchmarkChallenge,
    TemplateQuestionnaire,
    TemplatePaperScreening,
    TemplateDataDonation
  }

  describe "Migration from opt_out to opt_in verification" do
    test "BenchmarkChallenge template has correct opt-in flags" do
      template = %TemplateBenchmarkChallenge{id: :benchmark_challenge}
      tabs = Systems.Assignment.Template.tabs(template)

      # Check settings flags
      {_title, settings_flags} = tabs[:settings]
      assert settings_flags.branding == true
      assert settings_flags.information == true
      assert settings_flags.privacy == true
      assert settings_flags.consent == true
      assert settings_flags.helpdesk == true
      assert settings_flags.affiliate == true

      # Check participants flags
      {_title, participants_flags} = tabs[:participants]
      assert participants_flags.expected == false
      # was opt_out
      assert participants_flags.language == false
      assert participants_flags.invite_participants == true
      # was opt_out
      assert participants_flags.advert_in_pool == false
      # was opt_out
      assert participants_flags.affiliate == false
    end

    test "Questionnaire template has correct opt-in flags" do
      template = %TemplateQuestionnaire{id: :questionnaire}
      tabs = Systems.Assignment.Template.tabs(template)

      # Check settings flags - all should be enabled (was opt_out: [:panel, :storage])
      {_title, settings_flags} = tabs[:settings]
      assert settings_flags.branding == true
      assert settings_flags.information == true
      assert settings_flags.privacy == true
      assert settings_flags.consent == true
      assert settings_flags.helpdesk == true
      assert settings_flags.affiliate == true

      # Check participants flags - all should be enabled (was no opt_out)
      {_title, participants_flags} = tabs[:participants]
      assert participants_flags.advert_in_pool == true
      assert participants_flags.invite_participants == true
    end

    test "PaperScreening template has correct opt-in flags" do
      template = %TemplatePaperScreening{id: :paper_screening}
      tabs = Systems.Assignment.Template.tabs(template)

      # Check participants flags
      {_title, participants_flags} = tabs[:participants]
      assert participants_flags.invite_participants == true
      # was opt_out
      assert participants_flags.advert_in_pool == false
      # was opt_out
      assert participants_flags.affiliate == false
    end

    test "DataDonation template has correct opt-in flags" do
      template = %TemplateDataDonation{id: :data_donation}
      tabs = Systems.Assignment.Template.tabs(template)

      # Check settings flags - all should be enabled (was no opt_out)
      {_title, settings_flags} = tabs[:settings]
      assert settings_flags.branding == true
      assert settings_flags.information == true
      assert settings_flags.privacy == true
      assert settings_flags.consent == true
      assert settings_flags.helpdesk == true
      assert settings_flags.affiliate == true

      # Check participants flags
      {_title, participants_flags} = tabs[:participants]
      assert participants_flags.expected == true
      assert participants_flags.language == true
      assert participants_flags.affiliate == true
      # was opt_out
      assert participants_flags.advert_in_pool == false
      # was opt_out
      assert participants_flags.invite_participants == false
    end
  end

  describe "Demonstration that opt_out is deprecated but still works" do
    test "opt_out parameter works but shows deprecation warning" do
      # This demonstrates that opt_out still works for backwards compatibility
      # but shows a deprecation warning
      warning_output =
        capture_io(:stderr, fn ->
          flags = Flags.Settings.new(opt_out: [:branding])

          # With opt_out behavior, specified flags should be false, others true
          # in opt_out list
          # in opt_out list
          assert flags.branding == false
          # not in opt_out list
          assert flags.information == true
        end)

      # Should show deprecation warning
      assert warning_output =~ ":opt_out is deprecated"
    end

    test "opt_in takes precedence when both opt_in and opt_out are provided" do
      flags = Flags.Settings.new(opt_in: [:privacy], opt_out: [:branding, :information])

      # Only opt_in should take effect
      assert flags.privacy == true
      # opt_out ignored
      assert flags.branding == false
      # opt_out ignored
      assert flags.information == false
    end
  end
end
