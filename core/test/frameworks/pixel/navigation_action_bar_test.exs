defmodule Frameworks.Pixel.NavigationActionBarTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias Frameworks.Pixel.Navigation

  defp render_bar(more_buttons) do
    assigns = %{more_buttons: more_buttons}

    rendered = ~H"""
    <Navigation.action_bar breadcrumbs={[]} right_bar_buttons={[]} more_buttons={@more_buttons}>
      <div>tabs</div>
    </Navigation.action_bar>
    """

    rendered_to_string(rendered)
  end

  defp export_button do
    %{
      label: %{
        action: %{type: :send, event: "action_click", item: :export_setup},
        face: %{type: :plain, label: "Export study setup"}
      }
    }
  end

  test "hides the toggle when there are no more buttons" do
    html = render_bar([])

    refute html =~ ~s(id="action_menu_toggle")
    refute html =~ ~s(id="action_menu")
  end

  test "renders the toggle and its menu items when there are more buttons" do
    html = render_bar([export_button()])

    assert html =~ ~s(id="action_menu_toggle")
    assert html =~ ~s(target="action_menu")
    assert html =~ "Export study setup"
  end
end
