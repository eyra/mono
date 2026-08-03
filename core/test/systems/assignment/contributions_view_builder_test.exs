defmodule Systems.Assignment.ContributionsViewBuilderTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Assignment
  alias Systems.Assignment.ContributionsViewBuilder, as: Builder
  alias Systems.Crew

  describe "view_model/2 title" do
    setup do
      %{assignment: Assignment.Factories.create_assignment(31, 1)}
    end

    test "returns the given title", %{assignment: assignment} do
      assert %{title: "Contributions"} = Builder.view_model(assignment, %{title: "Contributions"})
    end

    test "defaults the title to an empty string when not given", %{assignment: assignment} do
      assert %{title: ""} = Builder.view_model(assignment, %{})
    end
  end

  describe "view_model/2 sections (no declined)" do
    setup do
      %{assignment: Assignment.Factories.create_assignment(31, 1)}
    end

    test "always includes the pending section first", %{assignment: assignment} do
      %{sections: sections} = Builder.view_model(assignment, %{})
      assert [{:pending, _} | _] = sections
    end

    test "always includes the confirmed section last", %{assignment: assignment} do
      %{sections: sections} = Builder.view_model(assignment, %{})
      assert [_ | rest] = sections
      assert {:confirmed, _} = List.last(rest)
    end

    test "omits the declined section when there are no declined rewards",
         %{assignment: assignment} do
      %{sections: sections} = Builder.view_model(assignment, %{})
      refute Enum.any?(sections, fn {key, _} -> key == :declined end)
    end

    test "pending section carries the ContributionsPendingView module descriptor",
         %{assignment: assignment} do
      %{sections: sections} = Builder.view_model(assignment, %{})

      assert {:pending,
              %{
                module: Assignment.ContributionsPendingView,
                id: "contributions-pending",
                rows: _,
                count: _
              }} = Enum.find(sections, &match?({:pending, _}, &1))
    end

    test "confirmed section carries the ContributionsConfirmedView module descriptor",
         %{assignment: assignment} do
      %{sections: sections} = Builder.view_model(assignment, %{})

      assert {:confirmed,
              %{
                module: Assignment.ContributionsConfirmedView,
                id: "contributions-confirmed",
                rows: _,
                count: _
              }} = Enum.find(sections, &match?({:confirmed, _}, &1))
    end
  end

  describe "view_model/2 sections (with declined)" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment(31, 1)
      %{crew: crew} = assignment
      _member = Crew.Factories.create_member(crew, user)

      {:ok, participation} = Assignment.Public.obtain_participation(assignment, user)
      {:ok, _} = Assignment.Public.reject_participation(participation, "not eligible")

      assignment = Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))
      %{assignment: assignment}
    end

    test "inserts the declined section between pending and confirmed",
         %{assignment: assignment} do
      %{sections: sections} = Builder.view_model(assignment, %{})

      keys = Enum.map(sections, fn {k, _} -> k end)
      assert keys == [:pending, :declined, :confirmed]
    end

    test "declined section carries the ContributionsDeclinedView module descriptor",
         %{assignment: assignment} do
      %{sections: sections} = Builder.view_model(assignment, %{})

      assert {:declined,
              %{
                module: Assignment.ContributionsDeclinedView,
                id: "contributions-declined",
                rows: _,
                count: _
              }} = Enum.find(sections, &match?({:declined, _}, &1))
    end
  end
end
