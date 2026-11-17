defmodule Mica.RegistryTest do
  use ExUnit.Case, async: true

  describe "on Mica's own composition" do
    test "Mica's systems register their tools, project item types and directors" do
      assert Enum.map(Mica.Tools.all(), & &1.type()) |> Enum.sort() ==
               ~w(alliance document feldspar instruction lab manual)

      assert Enum.map(Mica.ProjectItems.all(), & &1.type()) |> Enum.sort() ==
               ~w(advert assignment storage_endpoint)

      assert Mica.Directors.all() == %{
               advert: Systems.Advert.Director,
               assignment: Systems.Assignment.Director
             }
    end

    test "a tool type is found by its name, its struct and its schema" do
      assert Mica.Tools.fetch!("feldspar") == Systems.Feldspar.Tool
      assert Mica.Tools.type_of(%Systems.Feldspar.ToolModel{}) == "feldspar"
      assert Mica.Tools.type_of(Systems.Feldspar.ToolModel) == "feldspar"
      assert Mica.Tools.type_of(Systems.Assignment.Model) == nil
    end

    test "a name the composition doesn't have" do
      assert Mica.Tools.get("graphite") == nil
      assert Mica.Tools.get("none") == nil

      assert_raise ArgumentError, ~s(no tool type "graphite" in the composition), fn ->
        Mica.Tools.fetch!("graphite")
      end

      assert_raise ArgumentError, ~s(no project item type "none" in the composition), fn ->
        Mica.ProjectItems.fetch!("none")
      end
    end

    test "a project item type is found by its name and its target" do
      assert Mica.ProjectItems.fetch!("storage_endpoint") == Systems.Storage.ProjectItem
      assert Mica.ProjectItems.type_of(%Systems.Assignment.Model{}) == "assignment"
    end

    test "a director is found by its stored name" do
      assert Mica.Directors.get(:assignment) == Systems.Assignment.Director
      assert Mica.Directors.get("assignment") == Systems.Assignment.Director
      assert Mica.Directors.get("student") == nil
    end

    test "the type name of every Mica tool is its ToolModel key" do
      for tool <- Mica.Tools.all() do
        assert to_string(Frameworks.Concept.ToolModel.key(struct(tool.schema()))) == tool.type()
      end
    end
  end
end
