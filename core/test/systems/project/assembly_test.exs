defmodule Systems.Project.AssemblyTest do
  use Core.DataCase

  # alias Systems.{
  #   Project
  # }

  test "create_item/2" do
    %{root: _root} = Factories.insert!(:project, %{name: "AAP"})
  end
end
