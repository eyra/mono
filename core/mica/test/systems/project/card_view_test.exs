defmodule Systems.Project.CardViewTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Systems.Project

  defp card(left_actions, right_actions) do
    %{
      type: :secondary,
      id: 1,
      title: "Data",
      path: "/storage/endpoint/1/content",
      image_info: nil,
      icon_url: nil,
      label: %{type: :tertiary, text: "Storage"},
      tags: ["Storage"],
      info: ["0 files"],
      left_actions: left_actions,
      right_actions: right_actions
    }
  end

  test "a card without actions keeps the space of the actions row" do
    html = render_component(&Project.CardView.dynamic/1, card: card([], []))

    assert html =~ ~s(data-testid="card-actions-placeholder")
  end

  test "a card with actions has no placeholder" do
    delete = %{
      action: %{type: :send, event: "delete", item: 1},
      face: %{type: :icon, icon: :delete}
    }

    html = render_component(&Project.CardView.dynamic/1, card: card([], [delete]))

    refute html =~ ~s(data-testid="card-actions-placeholder")
  end
end
