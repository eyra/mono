defmodule Systems.Assignment.TemplateMigrationTest do
  use ExUnit.Case, async: true

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
end
