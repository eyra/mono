defmodule Frameworks.Pixel.Table do
  alias CoreWeb.UI.Timestamp
  use CoreWeb, :html

  attr(:layout, :list, required: true)
  attr(:head_cells, :list, required: true)
  attr(:rows, :list, required: true)
  attr(:border, :boolean, default: true)

  def table(assigns) do
    ~H"""
    <div class={"overflow-hidden #{if @border do "border-[2px] border-grey4 rounded-lg" end} w-full"}>
      <table class="w-full table-auto">
        <tbody>
          <.row top={true} cells={@head_cells} layout={@layout} border={@border}/>
          <%= for {cells, index} <- Enum.with_index(@rows) do %>
            <.row
              bottom={index == Enum.count(@rows)-1}
              cells={cells}
              layout={@layout}
              border={@border}
            />
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:cells, :list, required: true)
  attr(:layout, :list, required: true)
  attr(:top, :boolean, default: false)
  attr(:bottom, :boolean, default: false)
  attr(:border, :boolean, default: true)

  def row(assigns) do
    ~H"""
    <tr class={
      "h-12 w-full #{if not @top do "border-collapse border-y border-grey4 border-spacing-y-1" end}"}>
      <%= for {cell, index} <- Enum.with_index(@cells) do %>
        <.cell
          content={cell}
          left={index == 0}
          right={index == Enum.count(@cells)-1}
          layout={Enum.at(@layout, index)}
          top={@top}
          bottom={@bottom}
          border={@border}
        />
      <% end %>
    </tr>
    """
  end

  defp cell_padding(:top, %{border: true, top: true}), do: "pt-2"
  defp cell_padding(:left, %{border: true, left: true}), do: "pl-6"
  defp cell_padding(:right, %{border: true, right: true}), do: "pr-6"
  defp cell_padding(_, _), do: ""

  attr(:content, :string, required: true)
  attr(:layout, :map, required: true)
  attr(:top, :boolean, default: false)
  attr(:bottom, :boolean, default: false)
  attr(:left, :boolean, default: false)
  attr(:right, :boolean, default: false)
  attr(:border, :boolean, default: true)

  def cell(%{layout: layout, content: content} = assigns) do
    layout =
      if layout.type == :href and not valid_url?(content) do
        %{layout | type: :string}
      else
        layout
      end

    padding =
      [:top, :left, :right]
      |> Enum.map_join(" ", &cell_padding(&1, assigns))

    assigns = assign(assigns, %{padding: padding, layout: layout})

    ~H"""
    <td>
      <div class={"#{@padding}"}>
        <%= if @top do %>
          <Text.table_head align={@layout.align}><%= @content %></Text.table_head>
        <% else %>
          <Text.table_row align={@layout.align}>
            <.content type={@layout.type} value={@content} />
          </Text.table_row>
        <% end %>
      </div>
    </td>
    """
  end

  attr(:type, :atom, required: true)
  attr(:value, :string, required: true)

  def content(%{type: :href} = assigns) do
    ~H"""
      <a class="underline text-primary" href={@value} target="_blank">Link</a>
    """
  end

  def content(%{type: :date} = assigns) do
    ~H"""
      <%= Timestamp.stamp(@value) %>
    """
  end

  def content(assigns) do
    ~H"""
      <%= @value %>
    """
  end

  defp valid_url?(string) do
    uri = URI.parse(string)
    uri.scheme != nil && uri.host =~ "."
  end
end
