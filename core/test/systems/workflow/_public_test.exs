defmodule Systems.Workflow.PublicTest do
  use Core.DataCase

  alias Ecto.Multi

  alias Systems.Workflow
  alias Systems.Workflow.Factories

  test "rearrange/2 move last to first succeed" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    %{id: id_a} = item_a = Factories.create_item(workflow, tool_ref, 0)
    %{id: id_b} = item_b = Factories.create_item(workflow, tool_ref, 1)
    %{id: id_c} = item_c = Factories.create_item(workflow, tool_ref, 2)
    %{id: id_d} = item_d = Factories.create_item(workflow, tool_ref, 3)

    result =
      [item_a, item_b, item_c, item_d]
      |> Workflow.Public.rearrange(3, 0)

    assert [
             ok: %Systems.Workflow.ItemModel{
               id: ^id_d,
               position: 0
             },
             ok: %Systems.Workflow.ItemModel{
               id: ^id_a,
               position: 1
             },
             ok: %Systems.Workflow.ItemModel{
               id: ^id_b,
               position: 2
             },
             ok: %Systems.Workflow.ItemModel{
               id: ^id_c,
               position: 3
             }
           ] = result
  end

  test "rearrange/2 move first to last succeed" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    %{id: id_a} = item_a = Factories.create_item(workflow, tool_ref, 0)
    %{id: id_b} = item_b = Factories.create_item(workflow, tool_ref, 1)
    %{id: id_c} = item_c = Factories.create_item(workflow, tool_ref, 2)
    %{id: id_d} = item_d = Factories.create_item(workflow, tool_ref, 3)

    result =
      [item_a, item_b, item_c, item_d]
      |> Workflow.Public.rearrange(0, 3)

    assert [
             ok: %Systems.Workflow.ItemModel{
               id: ^id_b,
               position: 0
             },
             ok: %Systems.Workflow.ItemModel{
               id: ^id_c,
               position: 1
             },
             ok: %Systems.Workflow.ItemModel{
               id: ^id_d,
               position: 2
             },
             ok: %Systems.Workflow.ItemModel{
               id: ^id_a,
               position: 3
             }
           ] = result
  end

  test "update_position/2 move first to last succeed" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    %{id: id_a} = item_a = Factories.create_item(workflow, tool_ref, 0)
    %{id: id_b} = Factories.create_item(workflow, tool_ref, 1)
    %{id: id_c} = Factories.create_item(workflow, tool_ref, 2)
    %{id: id_d} = Factories.create_item(workflow, tool_ref, 3)

    {:ok, result} = Workflow.Public.update_position(item_a, 3)

    assert %{
             validate_new_position: true,
             validate_old_position: true,
             items: [
               %Systems.Workflow.ItemModel{
                 id: ^id_a,
                 position: 0
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_b,
                 position: 1
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_c,
                 position: 2
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_d,
                 position: 3
               }
             ],
             order_and_update: [
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_b,
                 position: 0
               },
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_c,
                 position: 1
               },
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_d,
                 position: 2
               },
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_a,
                 position: 3
               }
             ]
           } = result
  end

  test "update_position/2 move last to second succeed" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    %{id: id_a} = Factories.create_item(workflow, tool_ref, 0)
    %{id: id_b} = Factories.create_item(workflow, tool_ref, 1)
    %{id: id_c} = Factories.create_item(workflow, tool_ref, 2)
    %{id: id_d} = item_d = Factories.create_item(workflow, tool_ref, 3)

    {:ok, result} = Workflow.Public.update_position(item_d, 1)

    assert %{
             validate_new_position: true,
             validate_old_position: true,
             items: [
               %Systems.Workflow.ItemModel{
                 id: ^id_a,
                 position: 0
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_b,
                 position: 1
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_c,
                 position: 2
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_d,
                 position: 3
               }
             ],
             order_and_update: [
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_a,
                 position: 0
               },
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_d,
                 position: 1
               },
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_b,
                 position: 2
               },
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_c,
                 position: 3
               }
             ]
           } = result
  end

  test "update_position/2 move to same position succeeded" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    %{id: id_a} = Factories.create_item(workflow, tool_ref, 0)
    %{id: id_b} = Factories.create_item(workflow, tool_ref, 1)
    %{id: id_c} = Factories.create_item(workflow, tool_ref, 2)
    %{id: id_d} = item_d = Factories.create_item(workflow, tool_ref, 3)

    {:ok, result} = Workflow.Public.update_position(item_d, 3)

    assert %{
             items: [
               %Systems.Workflow.ItemModel{
                 id: ^id_a,
                 position: 0
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_b,
                 position: 1
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_c,
                 position: 2
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_d,
                 position: 3
               }
             ]
           } = result
  end

  test "update_position/2 out of upper bounds failure" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    Factories.create_item(workflow, tool_ref, 0)
    Factories.create_item(workflow, tool_ref, 1)
    Factories.create_item(workflow, tool_ref, 2)
    item_d = Factories.create_item(workflow, tool_ref, 3)

    {:error, :validate_new_position, :out_of_bounds, _} =
      Workflow.Public.update_position(item_d, 4)
  end

  test "update_position/2 out of lower bounds failure" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    Factories.create_item(workflow, tool_ref, 0)
    Factories.create_item(workflow, tool_ref, 1)
    Factories.create_item(workflow, tool_ref, 2)
    item_d = Factories.create_item(workflow, tool_ref, 3)

    {:error, :validate_new_position, :out_of_bounds, _} =
      Workflow.Public.update_position(item_d, -1)
  end

  test "update_position/2 position out of sync failure" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    Factories.create_item(workflow, tool_ref, 0)
    Factories.create_item(workflow, tool_ref, 1)
    item_c = Factories.create_item(workflow, tool_ref, 2)
    item_d = Factories.create_item(workflow, tool_ref, 3)

    Multi.new()
    |> Multi.update(:item_c, Workflow.ItemModel.changeset(item_c, %{position: 3}))
    |> Multi.update(:item_d, Workflow.ItemModel.changeset(item_d, %{position: 2}))
    |> Repo.transaction()

    {:error, :validate_old_position, :out_of_sync, _} = Workflow.Public.update_position(item_d, 1)
  end

  test "update_position/2 item deleted underwater success" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    Factories.create_item(workflow, tool_ref, 0)
    Factories.create_item(workflow, tool_ref, 1)
    item_c = Factories.create_item(workflow, tool_ref, 2)
    item_d = Factories.create_item(workflow, tool_ref, 3)

    Multi.new()
    |> Multi.delete(:item_c, item_c)
    |> Repo.transaction()

    {:error, :validate_old_position, :out_of_bounds, _} =
      Workflow.Public.update_position(item_d, 0)
  end

  test "delete/1 succeed" do
    tool = Factories.create_tool()
    tool_ref = Factories.create_tool_ref(tool)
    workflow = Factories.create_workflow()

    %{id: id_a} = Factories.create_item(workflow, tool_ref, 0)
    %{id: id_b} = Factories.create_item(workflow, tool_ref, 1)
    item_c = Factories.create_item(workflow, tool_ref, 2)
    %{id: id_d} = Factories.create_item(workflow, tool_ref, 3)

    {:ok, result} = Workflow.Public.delete(item_c)

    assert %{
             items: [
               %Systems.Workflow.ItemModel{
                 id: ^id_a,
                 position: 0
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_b,
                 position: 1
               },
               %Systems.Workflow.ItemModel{
                 id: ^id_d,
                 position: 3
               }
             ],
             order_and_update: [
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_a,
                 position: 0
               },
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_b,
                 position: 1
               },
               ok: %Systems.Workflow.ItemModel{
                 id: ^id_d,
                 position: 2
               }
             ]
           } = result
  end
end
