defmodule Systems.Storage.RunChartSVG do
  @moduledoc """
  Draws the charts of `Storage.RunChart` as one SVG, stacked, with a key on top.
  Colors are inline (Prism's primary and greys) so the same SVG works on the
  page and as a file in the export.
  """
  use Phoenix.Component
  use Gettext, backend: CoreWeb.Gettext

  @primary "#4272EF"
  @grey1 "#222222"
  @grey2 "#999999"
  @grey3 "#CCCCCC"
  @grey4 "#EEEEEE"
  @grey6 "#FAFAFA"
  @key_height 32
  @gap 16

  def labels do
    %{
      title: dgettext("eyra-storage", "donation.chart.title"),
      trial: dgettext("eyra-storage", "donation.chart.trial"),
      connection: dgettext("eyra-storage", "donation.chart.connection"),
      trend: dgettext("eyra-storage", "donation.chart.trend")
    }
  end

  @doc "The SVG as a string, for a file in the export."
  def render_string(assigns) do
    assigns
    |> Map.merge(%{standalone?: true, __changed__: nil})
    |> charts()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  attr(:charts, :list, required: true)
  attr(:labels, :map, required: true)
  attr(:heading, :string, default: nil)
  attr(:standalone?, :boolean, default: false)

  def charts(assigns) do
    heading_height = if assigns.heading, do: 32, else: 0
    width = Systems.Storage.RunChart.width()

    {offsets, height} =
      Enum.map_reduce(assigns.charts, heading_height + @key_height, fn %{height: h}, y ->
        {y, y + h + @gap}
      end)

    assigns =
      assign(assigns,
        width: width,
        height: height,
        offsets: offsets,
        heading_height: heading_height,
        colors: %{
          primary: @primary,
          grey1: @grey1,
          grey2: @grey2,
          grey3: @grey3,
          grey4: @grey4,
          grey6: @grey6
        }
      )

    ~H"""
    <svg
      xmlns={if @standalone?, do: "http://www.w3.org/2000/svg"}
      viewBox={"0 0 #{@width} #{@height}"}
      width={if @standalone?, do: @width}
      height={if @standalone?, do: @height}
      font-family="Nunito Sans, Helvetica, Arial, sans-serif"
      style="width: 100%; height: auto"
      role="img"
      aria-label={@labels.title}
      data-testid="run-chart"
    >
      <rect :if={@standalone?} width={@width} height={@height} fill="#FFFFFF" />
      <text :if={@heading} x="0" y="20" font-size="18" font-weight="700" fill={@colors.grey1}><%= @heading %></text>
      <g transform={"translate(0, #{@heading_height})"}>
        <circle cx="6" cy="14" r="4" fill={@colors.primary} stroke="#FFFFFF" stroke-width="2" />
        <text x="16" y="18" font-size="12" fill={@colors.grey1}><%= @labels.trial %></text>
        <line x1="96" x2="120" y1="14" y2="14" stroke={@colors.grey3} stroke-width="1" />
        <text x="126" y="18" font-size="12" fill={@colors.grey1}><%= @labels.connection %></text>
        <line x1="236" x2="260" y1="14" y2="14" stroke={@colors.primary} stroke-width="2" stroke-linecap="round" />
        <text x="266" y="18" font-size="12" fill={@colors.grey1}><%= @labels.trend %></text>
      </g>
      <%= for {chart, offset} <- Enum.zip(@charts, @offsets) do %>
        <g transform={"translate(0, #{offset})"} data-column={chart.column}>
          <.chart chart={chart} colors={@colors} />
        </g>
      <% end %>
    </svg>
    """
  end

  attr(:chart, :map, required: true)
  attr(:colors, :map, required: true)

  defp chart(assigns) do
    ~H"""
    <text x="0" y="14" font-size="13" font-weight="700" fill={@colors.grey1}><%= @chart.column %></text>
    <%= for band <- @chart.bands do %>
      <rect
        x={band.x}
        y={@chart.plot.top - 14}
        width={band.width}
        height={@chart.plot.bottom - @chart.plot.top + 14}
        fill={if band.shaded?, do: @colors.grey6, else: "#FFFFFF"}
      />
      <line x1={band.x} x2={band.x} y1={@chart.plot.top - 14} y2={@chart.plot.bottom} stroke={@colors.grey4} stroke-width="1" />
      <text :if={@chart.labels? and band.short_label} x={band.x + 8} y={@chart.plot.top - 2} font-size="12" fill={@colors.grey2}>
        <title><%= band.label %></title><%= band.short_label %>
      </text>
    <% end %>
    <%= for tick <- @chart.y_ticks do %>
      <line x1={@chart.plot.left} x2={@chart.plot.right} y1={tick.y} y2={tick.y} stroke={@colors.grey4} stroke-width="1" />
      <text x={@chart.plot.left - 8} y={tick.y + 4} font-size="12" text-anchor="end" fill={@colors.grey2} style="font-variant-numeric: tabular-nums">
        <%= tick.label %>
      </text>
    <% end %>
    <%= for band <- @chart.bands do %>
      <path :if={band.connection} d={band.connection} fill="none" stroke={@colors.grey3} stroke-width="1" />
      <path :if={band.trend} d={band.trend} fill="none" stroke={@colors.primary} stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
      <%= for point <- band.points do %>
        <g>
          <title><%= point.tooltip %></title>
          <circle cx={point.x} cy={point.y} r="10" fill="transparent" />
          <circle cx={point.x} cy={point.y} r="4" fill={@colors.primary} stroke="#FFFFFF" stroke-width="2" />
        </g>
      <% end %>
    <% end %>
    """
  end
end
