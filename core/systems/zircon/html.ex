defmodule Systems.Zircon.HTML do
  use CoreWeb, :html

  import Frameworks.Pixel.Table

  alias Systems.Paper

  attr(:items, :list, required: true)

  def paper_set_table(%{items: items} = assigns) do
    head_cells = [
      dgettext("eyra-zircon", "paper_set_table.doi.label"),
      dgettext("eyra-zircon", "paper_set_table.title.label"),
      dgettext("eyra-zircon", "paper_set_table.authors.label"),
      dgettext("eyra-zircon", "paper_set_table.year.label"),
      ""
    ]

    layout = [
      %{type: :text, width: "w-20", align: "text-left"},
      %{type: :text_truncate, width: "w-40", align: "text-left"},
      %{type: :text, width: "w-20", align: "text-left"},
      %{type: :text, width: "w-8", align: "text-left"},
      %{type: :action, width: "w-3", align: "text-right"}
    ]

    rows = items |> Enum.map(&paper_set_row/1)

    assigns = assign(assigns, head_cells: head_cells, layout: layout, rows: rows)

    ~H"""
      <.table border={false} layout={@layout} head_cells={@head_cells} rows={@rows} top_line?={true}/>
    """
  end

  defp paper_set_row(%{id: id, doi: doi, title: title, authors: authors, year: year}) do
    delete_button = %{
      action: %{type: :send, event: "delete", item: id},
      face: %{type: :icon, icon: :delete_red}
    }

    [doi, title, authors, year, delete_button]
  end

  attr(:items, :list, required: true)

  def ris_entry_table(%{items: items} = assigns) do
    head_cells = [
      dgettext("eyra-zircon", "paper_set_table.doi.label"),
      dgettext("eyra-zircon", "paper_set_table.title.label"),
      dgettext("eyra-zircon", "paper_set_table.authors.label"),
      dgettext("eyra-zircon", "paper_set_table.year.label")
    ]

    layout = [
      %{type: :text, width: "w-20", align: "text-left"},
      %{type: :text_truncate, width: "w-40", align: "text-left"},
      %{type: :text, width: "w-20", align: "text-left"},
      %{type: :text, width: "w-8", align: "text-left"},
      %{type: :action, width: "w-3", align: "text-right"}
    ]

    rows = items |> Enum.map(&ris_entry_row/1)

    assigns = assign(assigns, head_cells: head_cells, layout: layout, rows: rows)

    ~H"""
      <.table border={false} layout={@layout} head_cells={@head_cells} rows={@rows} top_line?={true}/>
    """
  end

  defp ris_entry_row(%{doi: doi, title: title, authors: authors, year: year}) do
    [doi, title, authors, year]
  end

  def ris_entry_error_table(%{errors: errors} = assigns) do
    head_cells = [
      dgettext("eyra-zircon", "ris_entry_error_table.line.label"),
      dgettext("eyra-zircon", "ris_entry_error_table.content.label"),
      dgettext("eyra-zircon", "ris_entry_error_table.error.label")
    ]

    layout = [
      %{type: :text, width: "w-16", align: "text-left"},
      %{type: :code, width: "w-64", align: "text-left"},
      %{type: :text, width: "flex-1", align: "text-left"}
    ]

    rows = errors |> Enum.map(&ris_entry_error_row/1)

    assigns = assign(assigns, head_cells: head_cells, layout: layout, rows: rows)

    ~H"""
      <.table border={false} layout={@layout} head_cells={@head_cells} rows={@rows} top_line?={true} id="ris-entry-error-table"/>
    """
  end

  defp ris_entry_error_row(%Paper.RISEntryError{line: line, message: message, content: content}) do
    displayed_content = content || "-"
    [line, displayed_content, message]
  end

  attr(:uploads, :map, required: true)
  attr(:import_button, :map, required: true)

  def ris_selector_form(assigns) do
    ~H"""
      <.form id={"ris_selector_form"} for={%{}} phx-change="change" phx-target="" >
        <div class="flex flex-row">
          <div class="hidden">
            <.live_file_input upload={@uploads.file} />
          </div>
          <div class="flex-wrap">
            <Button.dynamic {@import_button} />
          </div>
        </div>
      </.form>
    """
  end
end
