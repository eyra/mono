defmodule Systems.Benchmark.ImportForm do
  use CoreWeb, :live_component
  use CoreWeb.FileUploader, ~w(.csv)

  @impl true
  def process_file(socket, {_local_relative_path, local_full_path, remote_file}) do
    socket
    |> assign(csv_local_path: local_full_path)
    |> assign(csv_remote_file: remote_file)
  end

  @impl true
  def update(
        %{
          parent: parent,
          placeholder: placeholder,
          select_button: select_button,
          replace_button: replace_button,
          process_button: process_button
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        parent: parent,
        placeholder: placeholder,
        select_button: select_button,
        replace_button: replace_button,
        csv_local_path: nil,
        csv_remote_file: nil
      )
      |> init_file_uploader(:csv)
      |> prepare_process_button(process_button)
    }
  end

  defp prepare_process_button(socket, label) do
    process_button = %{
      action: %{type: :send, event: "process"},
      face: %{type: :primary, label: label}
    }

    assign(socket, process_button: process_button)
  end

  @impl true
  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "process",
        _params,
        %{assigns: %{parent: parent, csv_local_path: csv_local_path}} = socket
      ) do
    lines =
      csv_local_path
      |> File.stream!()
      |> CSV.decode(headers: true)

    lines_ok =
      lines
      |> Enum.filter(&filter_ok/1)
      |> Enum.map(&map/1)

    update_target(parent, %{csv_lines: lines_ok})
    {:noreply, socket}
  end

  defp filter_ok({:error, _}), do: false
  defp filter_ok(_), do: true

  defp map({:ok, line}), do: line
  defp map({:error, message}), do: message

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id="select_file_form" for={%{}} phx-change="change" phx-target="" >
        <div class="h-file-selector border-grey4 border-2 rounded pl-6 pr-6">
          <div class="flex flex-row items-center h-full">
            <div class="flex-grow">
              <%= if @csv_remote_file do %>
                <Text.body_large color="text-grey1"><%= @csv_remote_file %></Text.body_large>
              <% else %>
                <Text.body_large color="text-grey2"><%= @placeholder %></Text.body_large>
              <% end %>
            </div>
            <%= if @csv_remote_file do %>
              <Button.primary_label label={@replace_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.csv.ref} />
            <% else %>
              <Button.primary_label label={@select_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.csv.ref} />
            <% end %>
          </div>
          <%= live_file_input(@uploads.csv, class: "hidden") %>
        </div>
      </.form>
      <.spacing value="M" />
      <%= if @csv_local_path do %>
          <.wrap>
            <Button.dynamic {@process_button} />
          </.wrap>
      <% end %>

    </div>
    """
  end
end
