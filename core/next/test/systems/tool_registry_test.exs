defmodule Next.Systems.ToolRegistryTest do
  use Mica.DataCase, async: true

  alias Systems.Workflow

  # Every tool type Next composes; `Workflow.ToolRefModel` still holds each one in
  # a field named `<type>_tool` until code-registry's release 2.
  @types ~w(alliance document feldspar graphite instruction lab manual zircon_screening)

  test "Next composes the eight tool types, four project item types and four directors" do
    assert Enum.map(Mica.Tools.all(), & &1.type()) |> Enum.sort() == @types

    assert Enum.map(Mica.ProjectItems.all(), & &1.type()) |> Enum.sort() ==
             ~w(advert assignment leaderboard storage_endpoint)

    assert Mica.Directors.all() |> Map.keys() |> Enum.sort() ==
             [:advert, :assignment, :citizen, :student]
  end

  test "a tool type's prepare/2 builds the changeset Workflow.Public.prepare_tool/4 builds" do
    user = Factories.insert!(:member)

    for type <- @types do
      auth_node = Factories.insert!(:auth_node)
      attrs = %{director: :assignment}
      tool = Mica.Tools.fetch!(type)

      expected = Workflow.Public.prepare_tool(:"#{type}_tool", attrs, auth_node, user)
      prepared = tool.prepare(attrs, %{auth_node: auth_node, user: user, director: :assignment})

      assert prepared.data.__struct__ == tool.schema(), type
      assert comparable(prepared.changes) == comparable(expected.changes), type
      assert prepared.valid? == expected.valid?, type
    end
  end

  # Field changes compare by value. An association compares by its type and
  # length: some tools insert fresh records per call (Manual creates its manual,
  # Zircon its default criteria).
  defp comparable(changes), do: Map.new(changes, fn {key, value} -> {key, shape(value)} end)

  defp shape(values) when is_list(values), do: Enum.map(values, &shape/1)
  defp shape(%Ecto.Changeset{data: %module{}}), do: module
  defp shape(%module{__meta__: _}), do: module
  defp shape(value), do: value

  test "the type name of every tool is its ToolModel key" do
    for tool <- Mica.Tools.all() do
      assert to_string(Frameworks.Concept.ToolModel.key(struct(tool.schema()))) == tool.type()
    end
  end
end
