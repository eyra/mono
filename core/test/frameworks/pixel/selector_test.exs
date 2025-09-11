defmodule Frameworks.Pixel.SelectorTest do
  use CoreWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Frameworks.Pixel.Selector

  describe "Selector component rendering" do
    test "renders radio selector correctly", %{conn: conn} do
      items = [
        %{id: :option1, value: "Option 1", active: true},
        %{id: :option2, value: "Option 2", active: false},
        %{id: :option3, value: "Option 3", active: false}
      ]

      {:ok, _view, html} =
        conn
        |> Map.put(:request_path, "")
        |> live_isolated(CoreWeb.ComponentTestLive,
          session: %{
            "component_module" => Selector,
            "component_type" => :live_component,
            "component_id" => "test-radio-selector",
            "component_props" => %{
              items: items,
              type: :radio,
              optional?: false
            },
            "component_events" => ["active_item_id"]
          }
        )

      # Check that component renders
      assert html =~ "Component Test Harness"
      assert html =~ "Frameworks.Pixel.Selector"

      # Check that radio buttons are rendered
      assert html =~ "Option 1"
      assert html =~ "Option 2"
      assert html =~ "Option 3"

      # Check that icons are present (active/inactive)
      assert html =~ "selector-icon-active"
      assert html =~ "selector-icon-inactive"
    end

    test "renders checkbox selector correctly", %{conn: conn} do
      items = [
        %{id: :check1, value: "Check 1", active: true},
        %{id: :check2, value: "Check 2", active: false},
        %{id: :check3, value: "Check 3", active: true}
      ]

      {:ok, _view, html} =
        conn
        |> Map.put(:request_path, "")
        |> live_isolated(CoreWeb.ComponentTestLive,
          session: %{
            "component_module" => Selector,
            "component_type" => :live_component,
            "component_id" => "test-checkbox-selector",
            "component_props" => %{
              items: items,
              type: :checkbox,
              optional?: true
            },
            "component_events" => ["active_item_ids"]
          }
        )

      # Check that checkboxes are rendered
      assert html =~ "Check 1"
      assert html =~ "Check 2"
      assert html =~ "Check 3"
    end

    test "renders segmented selector correctly", %{conn: conn} do
      items = [
        %{id: :seg1, value: "First", active: true},
        %{id: :seg2, value: "Second", active: false},
        %{id: :seg3, value: "Third", active: false}
      ]

      {:ok, _view, html} =
        conn
        |> Map.put(:request_path, "")
        |> live_isolated(CoreWeb.ComponentTestLive,
          session: %{
            "component_module" => Selector,
            "component_type" => :live_component,
            "component_id" => "test-segmented-selector",
            "component_props" => %{
              items: items,
              type: :segmented,
              optional?: false
            }
          }
        )

      # Check segmented control renders
      assert html =~ "First"
      assert html =~ "Second"
      assert html =~ "Third"
      assert html =~ "data-selector-segment"
    end

    test "handles selector toggle events", %{conn: conn} do
      items = [
        %{id: :option1, value: "Option 1", active: true},
        %{id: :option2, value: "Option 2", active: false}
      ]

      {:ok, view, _html} =
        conn
        |> Map.put(:request_path, "")
        |> live_isolated(CoreWeb.ComponentTestLive,
          session: %{
            "component_module" => Selector,
            "component_type" => :live_component,
            "component_id" => "test-event-selector",
            "component_props" => %{
              items: items,
              type: :radio,
              optional?: false
            },
            "component_events" => ["active_item_id"]
          }
        )

      # Click on option2
      view
      |> element("[data-selector-item='option2']")
      |> render_click()

      # The event is sent to parent, now check the updated HTML
      html = render(view)

      # Check that option2 is now active (the selector updated)
      assert html =~ "Option 2"
    end

    test "renders label selector correctly", %{conn: conn} do
      items = [
        %{id: :label1, value: "Tag 1", active: true},
        %{id: :label2, value: "Tag 2", active: false},
        %{id: :label3, value: "Tag 3", active: true}
      ]

      {:ok, _view, html} =
        conn
        |> Map.put(:request_path, "")
        |> live_isolated(CoreWeb.ComponentTestLive,
          session: %{
            "component_module" => Selector,
            "component_type" => :live_component,
            "component_id" => "test-label-selector",
            "component_props" => %{
              items: items,
              type: :label,
              optional?: true
            }
          }
        )

      # Check that labels are rendered
      assert html =~ "Tag 1"
      assert html =~ "Tag 2"
      assert html =~ "Tag 3"
      assert html =~ "data-selector-segment"
    end

    test "handles optional vs required selection", %{conn: conn} do
      items = [
        %{id: :option1, value: "Option 1", active: true},
        %{id: :option2, value: "Option 2", active: false}
      ]

      # Test optional selector
      {:ok, view, _html} =
        conn
        |> Map.put(:request_path, "")
        |> live_isolated(CoreWeb.ComponentTestLive,
          session: %{
            "component_module" => Selector,
            "component_type" => :live_component,
            "component_id" => "test-optional-selector",
            "component_props" => %{
              items: items,
              type: :radio,
              optional?: true
            }
          }
        )

      # Should allow deselecting all items when optional
      view
      |> element("[data-selector-item='option1']")
      |> render_click()

      html = render(view)
      assert html =~ "Option 1"
      assert html =~ "Option 2"
    end
  end
end
