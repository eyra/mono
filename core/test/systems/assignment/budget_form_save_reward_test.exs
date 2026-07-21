defmodule Systems.Assignment.BudgetFormSaveRewardTest do
  @moduledoc """
  White-box coverage of `BudgetForm`'s `save_reward` event handler.

  Covers the error branch that Melle spotted: in the EN locale, typing
  "1,000.50" (thousands-style grouping) previously got silently reinterpreted
  by Cldr as `100050`. Now the parser rejects it and the handler must expose
  a changeset error on `:subject_reward` while keeping the user's raw text
  in the `reward_input` assign so the field doesn't clobber their input.
  """

  use ExUnit.Case, async: true

  alias Systems.Assignment.BudgetForm
  alias Systems.Assignment.InfoModel

  defp build_socket do
    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        assignment: %{info: %InfoModel{}},
        info: %InfoModel{},
        subject_count: 0
      }
    }
  end

  defp save_reward(raw_reward) do
    BudgetForm.handle_event(
      "save_reward",
      %{"info_model" => %{"subject_reward" => raw_reward}},
      build_socket()
    )
  end

  test "flags a thousands-style grouping with a changeset error" do
    {:noreply, socket} = save_reward("1,000.50")

    changeset = socket.assigns.reward_changeset
    assert changeset.action == :insert
    assert changeset.errors[:subject_reward]
  end

  test "keeps the user's raw input in reward_input on error" do
    {:noreply, socket} = save_reward("1,000.50")

    assert socket.assigns.reward_input == "1,000.50"
  end

  test "flags letters as an error" do
    {:noreply, socket} = save_reward("abc")

    changeset = socket.assigns.reward_changeset
    assert changeset.action == :insert
    assert changeset.errors[:subject_reward]
  end
end
