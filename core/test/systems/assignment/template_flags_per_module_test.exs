defmodule Systems.Assignment.TemplateFlagsPerModuleTest do
  use ExUnit.Case, async: true

  alias Systems.Assignment.Template.Flags

  describe "Settings flags module" do
    test "new/0 creates struct with all flags false" do
      flags = Flags.Settings.new()
      assert %Flags.Settings{} = flags

      # All flags should be false by default
      assert flags.branding == false
      assert flags.information == false
      assert flags.privacy == false
      assert flags.consent == false
      assert flags.helpdesk == false
      assert flags.affiliate == false
    end

    test "new/1 with opt_in enables specific flags" do
      flags = Flags.Settings.new(opt_in: [:privacy, :affiliate])

      # Specified flags should be true
      assert flags.privacy == true
      assert flags.affiliate == true

      # Others should be false
      assert flags.branding == false
      assert flags.information == false
      assert flags.consent == false
      assert flags.helpdesk == false
    end

    test "Access protocol works correctly" do
      flags = Flags.Settings.new(opt_in: [:privacy])

      # Access.fetch/2
      assert {:ok, true} = Access.fetch(flags, :privacy)
      assert {:ok, false} = Access.fetch(flags, :branding)
      assert :error = Access.fetch(flags, :nonexistent)

      # Bracket syntax
      assert flags[:privacy] == true
      assert flags[:branding] == false
      assert flags[:nonexistent] == nil
    end

    test "flags/0 returns available flags" do
      flags_list = Flags.Settings.flags()

      expected = [
        :branding,
        :information,
        :privacy,
        :consent,
        :helpdesk,
        :affiliate
      ]

      assert flags_list -- expected == []
    end

    test "backward compatibility with opt_out (deprecated)" do
      import ExUnit.CaptureIO

      # Should emit deprecation warning
      warning =
        capture_io(:stderr, fn ->
          flags = Flags.Settings.new(opt_out: [:privacy])

          # opt_out should work but invert the flags
          assert flags.privacy == false
          assert flags.branding == true
        end)

      assert warning =~ "opt_out is deprecated"
    end
  end

  describe "Participants flags module" do
    test "new/0 creates struct with all flags false" do
      flags = Flags.Participants.new()
      assert %Flags.Participants{} = flags

      assert flags.expected == false
      assert flags.language == false
      assert flags.advert_in_pool == false
      assert flags.invite_participants == false
      assert flags.affiliate == false
    end

    test "new/1 with opt_in enables specific flags" do
      flags = Flags.Participants.new(opt_in: [:advert_in_pool, :affiliate, :expected])

      assert flags.advert_in_pool == true
      assert flags.affiliate == true
      assert flags.expected == true
      assert flags.invite_participants == false
      assert flags.language == false
    end

    test "Access protocol works correctly" do
      flags = Flags.Participants.new(opt_in: [:advert_in_pool, :language])

      assert {:ok, true} = Access.fetch(flags, :advert_in_pool)
      assert {:ok, true} = Access.fetch(flags, :language)
      assert {:ok, false} = Access.fetch(flags, :invite_participants)
      assert :error = Access.fetch(flags, :nonexistent)
    end

    test "flags/0 returns available flags" do
      flags_list = Flags.Participants.flags()
      expected = [:expected, :language, :advert_in_pool, :invite_participants, :affiliate]
      assert flags_list -- expected == []
    end
  end

  describe "Workflow flags module" do
    test "new/0 creates struct with all flags false" do
      flags = Flags.Workflow.new()
      assert %Flags.Workflow{} = flags

      assert flags.library == false
    end

    test "new/1 with opt_in enables specific flags" do
      flags = Flags.Workflow.new(opt_in: [:library])

      assert flags.library == true
    end

    test "Access protocol works correctly" do
      flags = Flags.Workflow.new(opt_in: [:library])

      assert {:ok, true} = Access.fetch(flags, :library)
      assert flags[:library] == true
    end

    test "flags/0 returns available flags" do
      flags_list = Flags.Workflow.flags()
      expected = [:library]
      assert flags_list == expected
    end
  end

  describe "Monitor flags module" do
    test "new/0 creates struct with all flags false" do
      flags = Flags.Monitor.new()
      assert %Flags.Monitor{} = flags

      assert flags.consent == false
    end

    test "new/1 with opt_in enables specific flags" do
      flags = Flags.Monitor.new(opt_in: [:consent])

      assert flags.consent == true
    end

    test "Access protocol works correctly" do
      flags = Flags.Monitor.new(opt_in: [:consent])

      assert {:ok, true} = Access.fetch(flags, :consent)
      assert flags[:consent] == true
    end

    test "flags/0 returns available flags" do
      flags_list = Flags.Monitor.flags()
      expected = [:consent]
      assert flags_list == expected
    end
  end

  describe "Edge cases and error handling" do
    test "invalid flag names are ignored silently" do
      # Should not crash, just ignore invalid flags
      flags = Flags.Settings.new(opt_in: [:valid_flag, :invalid_flag, :branding])

      # Valid flags should work
      assert flags.branding == true

      # Invalid flags shouldn't cause issues
      assert flags.privacy == false
    end

    test "duplicate flags in opt_in list are handled correctly" do
      flags = Flags.Settings.new(opt_in: [:branding, :branding, :privacy])

      assert flags.branding == true
      assert flags.privacy == true
    end

    test "empty opt_in list behaves like new/0" do
      flags1 = Flags.Settings.new()
      flags2 = Flags.Settings.new(opt_in: [])

      assert flags1 == flags2
    end

    test "mixing opt_in and opt_out shows deprecation warning and prioritizes opt_in" do
      import ExUnit.CaptureIO

      warning =
        capture_io(:stderr, fn ->
          flags = Flags.Settings.new(opt_in: [:branding], opt_out: [:privacy])

          # opt_in should take precedence
          assert flags.branding == true
          # opt_out should be ignored when opt_in is present
        end)

      assert warning =~ "opt_out is deprecated"
    end
  end
end
