defmodule Next.Systems.SystemLookupTest do
  # Mica builds a system's module names at runtime; Next's systems are under Next.Systems.
  use ExUnit.Case, async: true

  alias Frameworks.Concept.System
  alias Frameworks.Utility.Module

  test "a system name finds Mica's director first, then the SaaS's" do
    assert System.director(:assignment) == Systems.Assignment.Director
    assert System.director(:student) == Next.Systems.Student.Director
    assert System.director(:citizen) == Next.Systems.Citizen.Director
  end

  test "a module finds the presenter of its own system" do
    assert System.presenter(Next.Systems.Student.Switch) == Next.Systems.Student.Presenter
    assert System.presenter(Systems.Advert.Switch) == Systems.Advert.Presenter
  end

  test "a SaaS system's model is named like a Mica system's" do
    assert Module.to_model(Next.Systems.Graphite.ToolModel) == "graphite_tool"
  end

  test "the system namespace of a module" do
    assert Module.system_namespace(Next.Systems.Zircon.Switch) == ["Next", "Systems", "Zircon"]
    assert Module.system_namespace(Systems.Pool.Model) == ["Systems", "Pool"]
    assert Module.system_namespace(Mica.Repo) == nil
  end
end
