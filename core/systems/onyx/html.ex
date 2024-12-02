defmodule Systems.Onyx.HTML do
  use CoreWeb, :html

  import Frameworks.Pixel.Table

  attr(:items, :list, required: true)

  def import_history(%{items: items} = assigns) do
    head_cells = [
      dgettext("eyra-onyx", "import_history.timestamp.label"),
      dgettext("eyra-onyx", "import_history.file.label"),
      dgettext("eyra-onyx", "import_history.errors.label"),
      dgettext("eyra-onyx", "import_history.all_count.label"),
      dgettext("eyra-onyx", "import_history.duplicate_count.label"),
      dgettext("eyra-onyx", "import_history.new_count.label"),
      ""
    ]

    layout = [
      %{type: :text, width: "w-40", align: "text-left"},
      %{type: :text, width: "", align: "text-left"},
      %{type: :text, width: "w-24", align: "text-left"},
      %{type: :text, width: "w-24", align: "text-left"},
      %{type: :text, width: "w-24", align: "text-left"},
      %{type: :text, width: "w-24", align: "text-left"},
      %{type: :action, width: "w-10", align: "text-right"}
    ]

    assigns = assign(assigns, head_cells: head_cells, layout: layout, rows: items)

    ~H"""
      <.table border={false} layout={@layout} head_cells={@head_cells} rows={@rows} />
    """
  end
end
