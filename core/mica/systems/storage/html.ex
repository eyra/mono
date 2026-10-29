defmodule Systems.Storage.Html do
  use CoreWeb, :html

  import Frameworks.Pixel.Table

  attr(:files, :list, required: true)
  attr(:endpoint_id, :integer, required: true)

  def files_table(%{files: files, endpoint_id: endpoint_id} = assigns) do
    head_cells = [
      dgettext("eyra-storage", "table.file.label"),
      dgettext("eyra-storage", "table.size.label"),
      dgettext("eyra-storage", "table.date.label"),
      ""
    ]

    layout = [
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :text, width: "w-40", align: "text-center"},
      %{type: :date, width: "w-60", align: "text-right"},
      %{type: :text, width: "w-20", align: "text-right"}
    ]

    rows =
      files
      |> Enum.map(fn %{path: path, size: size, timestamp: timestamp} ->
        [path, size, timestamp, donation_link(endpoint_id, path)]
      end)

    assigns = assign(assigns, head_cells: head_cells, layout: layout, rows: rows)

    ~H"""
      <.table layout={@layout} head_cells={@head_cells} rows={@rows} border={false} />
    """
  end

  # Pixel's :href cell only links hosts with a dot, so not localhost.
  defp donation_link(endpoint_id, path) do
    href = Phoenix.HTML.html_escape(~p"/storage/endpoint/#{endpoint_id}/donation?#{[path: path]}")

    Phoenix.HTML.raw(
      ~s(<a class="underline text-primary" href="#{Phoenix.HTML.safe_to_string(href)}">#{dgettext("eyra-storage", "table.view.label")}</a>)
    )
  end

  attr(:participants, :list, required: true)

  def participants_table(%{participants: participants} = assigns) do
    head_cells = [
      dgettext("eyra-storage", "table.participant.label"),
      dgettext("eyra-storage", "table.sessions.label"),
      dgettext("eyra-storage", "table.tools.label"),
      dgettext("eyra-storage", "table.files.label"),
      dgettext("eyra-storage", "table.last_donation.label")
    ]

    layout = [
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :text, width: "w-28", align: "text-center"},
      %{type: :text, width: "w-60", align: "text-left"},
      %{type: :text, width: "w-28", align: "text-center"},
      %{type: :text, width: "w-60", align: "text-right"}
    ]

    rows =
      Enum.map(participants, fn %{
                                  participant: participant,
                                  sessions: sessions,
                                  tools: tools,
                                  files: files,
                                  last_donation: last_donation
                                } ->
        [
          participant || dgettext("eyra-storage", "participants.unknown"),
          sessions,
          Enum.join(tools, ", "),
          files,
          last_donation
        ]
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
