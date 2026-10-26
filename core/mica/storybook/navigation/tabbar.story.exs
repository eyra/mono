defmodule Storybook.Frameworks.Pixel.Navigation.Tabbar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.tabbar/1

  # Full-width bar: one column and a full-width container keep it inside the variation box.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :default,
        description: "Centred navbar-height strip with a line below, wrapping a tab bar",
        slots: [
          """
          <Frameworks.Pixel.Tabbed.bar
            id="tabbar_tabs"
            initial_tab="settings"
            tabs={[
              %{id: "settings", title: "Settings"},
              %{id: "criteria", title: "Criteria"},
              %{id: "monitor", title: "Monitor"}
            ]}
          />
          """
        ]
      }
    ]
  end
end
