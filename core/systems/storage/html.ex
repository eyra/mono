defmodule Systems.Storage.Html do
  use CoreWeb, :html

  import Frameworks.Pixel.Table

  attr(:files, :list, required: true)

  def files_table(%{files: files} = assigns) do
    head_cells = [
      dgettext("eyra-storage", "table.file.label"),
      dgettext("eyra-storage", "table.size.label"),
      dgettext("eyra-storage", "table.date.label")
    ]

    layout = [
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :text, width: "w-40", align: "text-center"},
      %{type: :date, width: "w-60", align: "text-right"}
    ]

    rows =
      files
      |> Enum.map(fn %{path: path, size: size, timestamp: timestamp} ->
        [path, size, timestamp]
      end)

    assigns = assign(assigns, head_cells: head_cells, layout: layout, rows: rows)

    ~H"""
      <.table layout={@layout} head_cells={@head_cells} rows={@rows} border={false} />
    """
  end

  attr(:connected?, :boolean, required: true)

  def account_status(%{connected?: connected?} = assigns) do
    {label, icon} =
      if connected? do
        {dgettext("eyra-storage", "account.status.valid"), "ready.svg"}
      else
        {dgettext("eyra-storage", "account.status.invalid"), "warning.svg"}
      end

    assigns = assign(assigns, label: label, icon: icon)

    ~H"""
    <div class="flex flex-row items-center gap-2">
      <div class="w-6 h-6">
        <img src={~p"/images/icons/#{@icon}"} alt={@label}>
      </div>
      <Text.caption color="text-grey2" padding=""><%= @label %></Text.caption>
    </div>
    """
  end
end
