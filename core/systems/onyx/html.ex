defmodule Systems.Onyx.HTML do
  use CoreWeb, :html

  import Frameworks.Pixel.Table

  alias CoreWeb.UI.Timestamp
  alias Systems.Onyx

  attr(:tool_files, :list, required: true)
  attr(:timezone, :string, required: true)

  def import_history(%{tool_files: tool_files, timezone: timezone} = assigns) do
    head_cells = [
      dgettext("eyra-onyx", "import_history.timestamp.label"),
      dgettext("eyra-onyx", "import_history.file.label"),
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
      %{type: :button, width: "w-10", align: "text-right"}
    ]

    rows =
      tool_files
      |> Enum.map(fn %Onyx.ToolFileAssociation{
                       id: tool_file_id,
                       file: %{name: name, inserted_at: inserted_at},
                       associated_papers: associated_papers
                     } ->
        all_count = Enum.count(associated_papers)
        duplicate_count = 0
        new_count = all_count

        timestamp =
          inserted_at
          |> Timestamp.apply_timezone(timezone)
          |> Timestamp.format!()

        delete_button = %{
          action: %{type: :send, event: "delete_tool_file", item: tool_file_id},
          face: %{
            type: :icon,
            icon: :delete,
            color: :red
          }
        }

        [timestamp, name, all_count, duplicate_count, new_count, delete_button]
      end)

    assigns = assign(assigns, head_cells: head_cells, layout: layout, rows: rows)

    ~H"""
      <.table border={false} layout={@layout} head_cells={@head_cells} rows={@rows} />
    """
  end
end
