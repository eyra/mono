defmodule Systems.DataDonation.PublicTest do
  use Core.DataCase

  alias Core.Factories
  alias Ecto.Multi

  alias Systems.{
    DataDonation
  }

  test "rearrange/2 move last to first succeed" do
    tool = create_tool()
    %{id: id_a} = task_a = create_task(tool, create_document_task(), 0)
    %{id: id_b} = task_b = create_task(tool, create_document_task(), 1)
    %{id: id_c} = task_c = create_task(tool, create_document_task(), 2)
    %{id: id_d} = task_d = create_task(tool, create_document_task(), 3)

    result =
      [task_a, task_b, task_c, task_d]
      |> DataDonation.Public.rearrange(3, 0)

    assert [
             ok: %Systems.DataDonation.TaskModel{
               id: ^id_d,
               position: 0
             },
             ok: %Systems.DataDonation.TaskModel{
               id: ^id_a,
               position: 1
             },
             ok: %Systems.DataDonation.TaskModel{
               id: ^id_b,
               position: 2
             },
             ok: %Systems.DataDonation.TaskModel{
               id: ^id_c,
               position: 3
             }
           ] = result
  end

  test "rearrange/2 move first to last succeed" do
    tool = create_tool()
    %{id: id_a} = task_a = create_task(tool, create_document_task(), 0)
    %{id: id_b} = task_b = create_task(tool, create_document_task(), 1)
    %{id: id_c} = task_c = create_task(tool, create_document_task(), 2)
    %{id: id_d} = task_d = create_task(tool, create_document_task(), 3)

    result =
      [task_a, task_b, task_c, task_d]
      |> DataDonation.Public.rearrange(0, 3)

    assert [
             ok: %Systems.DataDonation.TaskModel{
               id: ^id_b,
               position: 0
             },
             ok: %Systems.DataDonation.TaskModel{
               id: ^id_c,
               position: 1
             },
             ok: %Systems.DataDonation.TaskModel{
               id: ^id_d,
               position: 2
             },
             ok: %Systems.DataDonation.TaskModel{
               id: ^id_a,
               position: 3
             }
           ] = result
  end

  test "update_position/2 move first to last succeed" do
    tool = create_tool()
    %{id: id_a} = task_a = create_task(tool, create_document_task(), 0)
    %{id: id_b} = create_task(tool, create_document_task(), 1)
    %{id: id_c} = create_task(tool, create_document_task(), 2)
    %{id: id_d} = create_task(tool, create_document_task(), 3)

    {:ok, result} = DataDonation.Public.update_position(task_a, 3)

    assert %{
             validate_new_position: true,
             validate_old_position: true,
             tasks: [
               %Systems.DataDonation.TaskModel{
                 id: ^id_a,
                 position: 0
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_b,
                 position: 1
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_c,
                 position: 2
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_d,
                 position: 3
               }
             ],
             order_and_update: [
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_b,
                 position: 0
               },
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_c,
                 position: 1
               },
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_d,
                 position: 2
               },
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_a,
                 position: 3
               }
             ]
           } = result
  end

  test "update_position/2 move last to second succeed" do
    tool = create_tool()
    %{id: id_a} = create_task(tool, create_document_task(), 0)
    %{id: id_b} = create_task(tool, create_document_task(), 1)
    %{id: id_c} = create_task(tool, create_document_task(), 2)
    %{id: id_d} = task_d = create_task(tool, create_document_task(), 3)

    {:ok, result} = DataDonation.Public.update_position(task_d, 1)

    assert %{
             validate_new_position: true,
             validate_old_position: true,
             tasks: [
               %Systems.DataDonation.TaskModel{
                 id: ^id_a,
                 position: 0
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_b,
                 position: 1
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_c,
                 position: 2
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_d,
                 position: 3
               }
             ],
             order_and_update: [
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_a,
                 position: 0
               },
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_d,
                 position: 1
               },
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_b,
                 position: 2
               },
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_c,
                 position: 3
               }
             ]
           } = result
  end

  test "update_position/2 move to same position succeeded" do
    tool = create_tool()
    %{id: id_a} = create_task(tool, create_document_task(), 0)
    %{id: id_b} = create_task(tool, create_document_task(), 1)
    %{id: id_c} = create_task(tool, create_document_task(), 2)
    %{id: id_d} = task_d = create_task(tool, create_document_task(), 3)

    {:ok, result} = DataDonation.Public.update_position(task_d, 3)

    assert %{
             tasks: [
               %Systems.DataDonation.TaskModel{
                 id: ^id_a,
                 position: 0
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_b,
                 position: 1
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_c,
                 position: 2
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_d,
                 position: 3
               }
             ]
           } = result
  end

  test "update_position/2 out of upper bounds failure" do
    tool = create_tool()
    create_task(tool, create_document_task(), 0)
    create_task(tool, create_document_task(), 1)
    create_task(tool, create_document_task(), 2)
    task_d = create_task(tool, create_document_task(), 3)

    {:error, :validate_new_position, :out_of_bounds, _} =
      DataDonation.Public.update_position(task_d, 4)
  end

  test "update_position/2 out of lower bounds failure" do
    tool = create_tool()
    create_task(tool, create_document_task(), 0)
    create_task(tool, create_document_task(), 1)
    create_task(tool, create_document_task(), 2)
    task_d = create_task(tool, create_document_task(), 3)

    {:error, :validate_new_position, :out_of_bounds, _} =
      DataDonation.Public.update_position(task_d, -1)
  end

  test "update_position/2 position out of sync failure" do
    tool = create_tool()
    create_task(tool, create_document_task(), 0)
    create_task(tool, create_document_task(), 1)
    task_c = create_task(tool, create_document_task(), 2)
    task_d = create_task(tool, create_document_task(), 3)

    Multi.new()
    |> Multi.update(:task_c, DataDonation.TaskModel.changeset(task_c, %{position: 3}))
    |> Multi.update(:task_d, DataDonation.TaskModel.changeset(task_d, %{position: 2}))
    |> Repo.transaction()

    {:error, :validate_old_position, :out_of_sync, _} =
      DataDonation.Public.update_position(task_d, 1)
  end

  test "update_position/2 item deleted underwater success" do
    tool = create_tool()
    create_task(tool, create_document_task(), 0)
    create_task(tool, create_document_task(), 1)
    task_c = create_task(tool, create_document_task(), 2)
    task_d = create_task(tool, create_document_task(), 3)

    Multi.new()
    |> Multi.delete(:task_c, task_c)
    |> Repo.transaction()

    {:error, :validate_old_position, :out_of_bounds, _} =
      DataDonation.Public.update_position(task_d, 0)
  end

  test "delete/1 succeed" do
    tool = create_tool()
    %{id: id_a} = create_task(tool, create_document_task(), 0)
    %{id: id_b} = create_task(tool, create_document_task(), 1)
    task_c = create_task(tool, create_document_task(), 2)
    %{id: id_d} = create_task(tool, create_document_task(), 3)

    {:ok, result} = DataDonation.Public.delete(task_c)

    assert %{
             tasks: [
               %Systems.DataDonation.TaskModel{
                 id: ^id_a,
                 position: 0
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_b,
                 position: 1
               },
               %Systems.DataDonation.TaskModel{
                 id: ^id_d,
                 position: 3
               }
             ],
             order_and_update: [
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_a,
                 position: 0
               },
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_b,
                 position: 1
               },
               ok: %Systems.DataDonation.TaskModel{
                 id: ^id_d,
                 position: 2
               }
             ]
           } = result
  end

  defp create_tool() do
    Factories.insert!(:data_donation_tool)
  end

  defp create_task(tool, document_task, index) do
    Factories.insert!(:data_donation_task, %{
      tool: tool,
      document_task: document_task,
      position: index
    })
  end

  defp create_document_task() do
    Factories.insert!(:data_donation_document_task)
  end
end
