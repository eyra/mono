defmodule Systems.Graphite.ToolViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Graphite

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      tool = Graphite.Factories.create_tool()

      %{user: user, tool: tool}
    end

    test "builds correct VM with all required fields", %{user: user, tool: tool} do
      assigns = build_assigns(user, "UTC")

      vm = Graphite.ToolViewBuilder.view_model(tool, assigns)

      # Should have tool
      assert vm.tool.id == tool.id

      # Should have submission (nil if no submission exists)
      # (Tested separately in submission test)

      # Should have open_for_submissions? flag
      assert is_boolean(vm.open_for_submissions?)

      # Should have leaderboard description
      assert vm.leaderboard_description == dgettext("eyra-graphite", "leaderboard.description")

      # Should have done button
      assert vm.done_button.action.type == :send
      assert vm.done_button.action.event == "done"
      assert vm.done_button.face.type == :primary
      assert vm.done_button.face.label == dgettext("eyra-ui", "done.button")

      # Should have submission form configured
      assert vm.submission_form.module == Graphite.SubmissionForm
      assert vm.submission_form.id == :submission_form
      assert vm.submission_form.tool.id == tool.id
      assert vm.submission_form.user == user
      assert vm.submission_form.timezone == "UTC"
      assert is_boolean(vm.submission_form.open?)
    end

    test "builds leaderboard button when leaderboard is online and submissions closed", %{
      user: user,
      tool: tool
    } do
      # Create online leaderboard
      leaderboard =
        Graphite.Factories.create_leaderboard(tool, %{status: :online, title: "Test Leaderboard"})

      # Set tool to closed for submissions (past deadline)
      tool = Repo.preload(tool, [:leaderboard], force: true)
      past_date = DateTime.from_naive!(~N[2020-01-01 00:00:00], "Etc/UTC")
      tool = Ecto.Changeset.change(tool, %{deadline: past_date})
      {:ok, tool} = Repo.update(tool)
      tool = Repo.preload(tool, [:leaderboard], force: true)

      assigns = build_assigns(user, "UTC")
      vm = Graphite.ToolViewBuilder.view_model(tool, assigns)

      # Should have leaderboard button
      assert vm.leaderboard_button != nil
      assert vm.leaderboard_button.action.type == :http_get
      assert vm.leaderboard_button.action.to == "/graphite/leaderboard/#{leaderboard.id}"
      assert vm.leaderboard_button.action.target == "_blank"
      assert vm.leaderboard_button.face.type == :plain
      assert vm.leaderboard_button.face.icon == :forward

      assert vm.leaderboard_button.face.label ==
               dgettext("eyra-graphite", "leaderboard.goto.button")
    end

    test "does not build leaderboard button when still open for submissions", %{
      user: user,
      tool: tool
    } do
      # Create online leaderboard but keep submissions open
      _leaderboard =
        Graphite.Factories.create_leaderboard(tool, %{status: :online, title: "Test Leaderboard"})

      # Set tool to open for submissions (future deadline)
      tool = Repo.preload(tool, [:leaderboard], force: true)
      future_date = DateTime.from_naive!(~N[2099-01-01 00:00:00], "Etc/UTC")
      tool = Ecto.Changeset.change(tool, %{deadline: future_date})
      {:ok, tool} = Repo.update(tool)
      tool = Repo.preload(tool, [:leaderboard], force: true)

      assigns = build_assigns(user, "UTC")
      vm = Graphite.ToolViewBuilder.view_model(tool, assigns)

      # Should NOT have leaderboard button when open
      assert vm.leaderboard_button == nil
    end

    test "does not build leaderboard button when leaderboard is offline", %{
      user: user,
      tool: tool
    } do
      # Create offline leaderboard
      _leaderboard =
        Graphite.Factories.create_leaderboard(tool, %{status: :offline, title: "Test Leaderboard"})

      tool = Repo.preload(tool, [:leaderboard], force: true)

      assigns = build_assigns(user, "UTC")
      vm = Graphite.ToolViewBuilder.view_model(tool, assigns)

      # Should NOT have leaderboard button when offline
      assert vm.leaderboard_button == nil
    end
  end

  # Helper functions
  defp build_assigns(user, timezone) do
    %{
      current_user: user,
      timezone: timezone
    }
  end
end
