defmodule Systems.Assignment.TemplateAccessBehaviorTest do
  use ExUnit.Case, async: true

  alias Systems.Assignment.Template.Flags

  describe "Access behavior verification" do
    test "flags can be accessed using bracket notation like the original error showed" do
      # This reproduces the exact scenario that was failing in the error message
      flags = %Flags.Participants{
        advert_in_pool: true,
        invite_participants: true,
        affiliate: true
      }

      # This should work now that we have Access behavior implemented
      assert flags[:advert_in_pool] == true
      assert flags[:invite_participants] == true
      assert flags[:affiliate] == true
    end

    test "flags work with Access.get/3 as used internally by bracket notation" do
      flags = Flags.Settings.new(opt_in: [:branding])

      # These should all work with the Access behavior
      assert Access.get(flags, :branding) == true
      assert Access.get(flags, :information) == false
      assert Access.get(flags, :non_existent, :default_value) == :default_value
    end

    test "flags work with get_in/2 for nested access" do
      container = %{flags: Flags.Workflow.new(opt_in: [:library])}

      # This should work with nested access
      assert get_in(container, [:flags, :library]) == true
    end

    test "flags work with put_in/3 for updates" do
      flags = Flags.Monitor.new()

      # Should be able to update using put_in
      updated_flags = put_in(flags[:consent], true)
      assert updated_flags.consent == true
    end

    test "flags work with update_in/3 for functional updates in Settings" do
      flags = Flags.Settings.new(opt_in: [:branding])

      # Should be able to functionally update
      updated_flags = update_in(flags[:branding], fn current -> not current end)
      assert updated_flags.branding == false
    end

    test "flags work with update_in/3 for functional updates in Participants" do
      flags = Flags.Participants.new(opt_in: [:language])

      # Should be able to functionally update
      updated_flags = update_in(flags[:language], fn current -> not current end)
      assert updated_flags.language == false
    end
  end

  describe "Backward compatibility with map-like operations" do
    test "Map.get/3 works on flag structs" do
      flags = Flags.Participants.new(opt_in: [:invite_participants])

      assert Map.get(flags, :invite_participants) == true
      assert Map.get(flags, :advert_in_pool) == false
      assert Map.get(flags, :non_existent, :default) == :default
    end

    test "Map operations work on flag structs" do
      flags = Flags.Participants.new(opt_in: [:invite_participants, :language])

      # Count true flags using Map functions
      true_count =
        flags
        |> Map.from_struct()
        |> Enum.reduce(0, fn {_key, value}, acc ->
          if value, do: acc + 1, else: acc
        end)

      # only invite_participants and language should be true
      assert true_count == 2
    end
  end
end
