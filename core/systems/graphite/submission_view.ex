defmodule Systems.Graphite.SubmissionView do
  use CoreWeb, :html

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Panel

  attr(:items, :list, required: true)

  def list(assigns) do
    ~H"""
      <%= if Enum.count(@items) > 0 do %>
        <table>
          <tbody>
          <%= for item <- @items do %>
            <.list_item {item} />
          <% end %>
          </tbody>
        </table>
      <% end %>
    """
  end

  attr(:description, :string, required: true)
  attr(:team, :string, default: nil)
  attr(:summary, :string, required: true)
  attr(:url, :string, required: true)
  attr(:buttons, :list, required: true)

  def list_item(assigns) do
    ~H"""
    <tr class="h-12">
      <%= if @team do %>
      <td class="pl-0">
        <Text.body_medium><%= @team %></Text.body_medium>
      </td>
      <% end %>
      <td class={if @team do "pl-8" else "pl-0" end}>
       <Text.body_medium><%= @description %></Text.body_medium>
      </td>
      <td class="pl-8">
        <Text.body_medium><%= @summary %></Text.body_medium>
      </td>
      <td class="pl-8">
        <Text.body_medium>
          <a class="text-primary underline" target="_blank" href={@url}>Github</a>
        </Text.body_medium>
      </td>
      <td class="pl-12">
        <div class="flex flex-row gap-4">
          <%= for button <- @buttons do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </td>
    </tr>
    """
  end

  attr(:description, :string, required: true)
  attr(:github_commit_url, :string, required: true)
  attr(:updated_at, :any, required: true)
  attr(:timezone, :any, required: true)

  def panel(assigns) do
    ~H"""
      <Panel.flat bg_color="bg-grey5">
        <div class="flex flex-row gap-4 items-center justify-center">
          <Text.title4>
            <%= @description %>
          </Text.title4>
          <%= if @timezone do %>
            <Text.body>
              Submitted <%= Timestamp.humanize(Timestamp.convert(@updated_at, @timezone)) %>
            </Text.body>
          <% end %>
          <div class="flex-grow" />
          <Button.dynamic {%{
            action: %{type: :http_get, to: @github_commit_url, target: "_blank"},
            face: %{type: :primary, label: "Open in Github"}
          }} />
        </div>
      </Panel.flat>
    """
  end
end
