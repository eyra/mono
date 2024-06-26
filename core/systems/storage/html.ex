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
end
