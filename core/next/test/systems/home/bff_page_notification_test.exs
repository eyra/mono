defmodule Next.Systems.Home.BFFPageNotificationTest do
  @moduledoc """
  The app's Home (`/bff/page/home`) shows a next action that a notification
  shows, such as a license To-do, with a button to where it leads. On the web
  that button POSTs (`Notify.Public.open_action/2`); the app gets the stored
  target instead, and showing Home marks nothing seen.
  """
  use NextWeb.ConnCase, async: false

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.BFF.Blocks
  alias Systems.Home.BFFPage
  alias Systems.Notify

  defp notify(user, type) do
    {:ok, _} =
      Notify.Public.record_event(%Notify.EventAttrs{
        type: type,
        subject_user: user,
        correlation_id: "license:publish",
        metadata: %{"license" => "publish", "valid_until" => "2027-11-26"}
      })

    :ok
  end

  defp next_best_action(user) do
    {blocks, _borders} = BFFPage.view_model(user, %{})
    Enum.find(blocks, &match?(%Blocks.NextBestAction{}, &1))
  end

  setup do
    %{user: Factories.insert!(:creator)}
  end

  test "a license given leads to Projects", %{user: user} do
    notify(user, :license_given)

    assert %Blocks.NextBestAction{to: "/project", cta: "Go to projects"} = next_best_action(user)
  end

  test "a license reminder leads to the helpdesk page", %{user: user} do
    notify(user, :license_reminder)

    assert %Blocks.NextBestAction{to: "/support/helpdesk"} = next_best_action(user)
  end

  test "showing Home marks nothing seen", %{user: user} do
    notify(user, :license_given)

    next_best_action(user)

    assert [%Notify.MessageModel{status: :sent}] = Repo.all(Notify.MessageModel)
  end
end
