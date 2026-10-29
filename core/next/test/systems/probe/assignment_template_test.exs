defmodule Systems.Probe.AssignmentTemplateTest do
  use Core.DataCase, async: false
  use Core.FeatureFlags.Test

  alias Frameworks.Builder
  alias Systems.Assignment
  alias Systems.Probe
  alias Systems.Project

  test "Next registers the Probe template" do
    assert Assignment.TemplateExtension.get(:probe) == Probe.AssignmentTemplate
  end

  describe "creating a project item" do
    setup do
      user = Factories.insert!(:member, %{creator: true})
      %{root: root} = Factories.insert!(:project, %{name: "Project"})
      %{user: user, root: root}
    end

    test "creates a Probe assignment named after the template", %{user: user, root: root} do
      name = Project.ItemTemplates.name(:probe)

      {:ok, %{project_item: %{id: id}}} = Project.Assembly.create_item(:probe, name, root, user)

      assert %{name: "Cognitive screening", assignment: %Assignment.Model{special: :probe}} =
               item = Project.Public.get_item!(id, Project.ItemModel.preload_graph(:down))

      assert Assignment.Template.title(Assignment.Private.get_template(item.assignment)) ==
               "Cognitive screening"
    end
  end

  describe "workflow library" do
    test "offers the cognitive task as a Feldspar zip tool" do
      %{library: %{items: items}} =
        Assignment.Template.workflow_config(Assignment.Private.get_template(:probe))

      assert %Builder.LibraryItemModel{type: :feldspar_tool, title: "Cognitive task"} =
               Enum.find(items, &(&1.id == :cognitive_tool))

      refute Enum.any?(items, &(&1.id == :donate))
    end
  end

  describe "feature flag" do
    test "the template is offered for new items when :probe is on" do
      set_feature_flag(:probe, true)

      assert %{id: :probe, value: "Cognitive screening", active: false} in Project.ItemTemplates.extension_labels()
    end

    test "the template is not offered for new items when :probe is off" do
      set_feature_flag(:probe, false)

      refute Enum.any?(Project.ItemTemplates.extension_labels(), &(&1.id == :probe))
    end

    test "is off in Next by default" do
      assert Next.SaaS.feature_flags()[:probe] == false
    end
  end

  describe "start screen text" do
    test "presents the cognitive task as a task, not a data donation" do
      description = Probe.AssignmentTemplate.tool_description(:cognitive_tool)

      assert description =~ "start a task"
      refute description =~ "donat"
    end

    test "names the task without the word test in English and Dutch" do
      for {locale, title} <- [{"en", "Cognitive task"}, {"nl", "Cognitieve taak"}] do
        Gettext.with_locale(CoreWeb.Gettext, locale, fn ->
          %{library: %{items: items}} =
            Assignment.Template.workflow_config(Assignment.Private.get_template(:probe))

          item = Enum.find(items, &(&1.id == :cognitive_tool))

          texts = [
            item.title,
            item.description,
            Probe.AssignmentTemplate.tool_description(:cognitive_tool)
          ]

          assert item.title == title
          refute Enum.any?(texts, &(&1 =~ ~r/test|toets/i))
        end)
      end
    end

    test "leaves other tasks to their default text" do
      assert Probe.AssignmentTemplate.tool_description(:donate) == nil
      assert Assignment.TemplateExtension.tool_description(:donate) == nil
    end
  end
end
