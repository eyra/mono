defmodule Systems.Instruction.DownloadForm do
  use CoreWeb, :live_component
  use CoreWeb.FileUploader, accept: ~w(.zip)

  import CoreWeb.Gettext
  import Frameworks.Pixel.Components.FileSelector

  alias Systems.Instruction
  alias Systems.Content

  @impl true
  def process_file(socket, {_path, url, original_filename}) do
    socket
    |> handle_save(original_filename, url)
    |> update_file()
    |> update_filename()
  end

  @impl true
  def update(%{id: id, entity: tool}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        tool: tool
      )
      |> update_page()
      |> update_file()
      |> update_filename()
      |> init_file_uploader(:file)
    }
  end

  defp update_file(%{assigns: %{tool: %{assets: [%{file: file} | _]}}} = socket)
       when not is_nil(file) do
    socket |> assign(file: file)
  end

  defp update_file(socket) do
    socket |> assign(file: nil)
  end

  defp update_filename(%{assigns: %{file: %{name: filename}}} = socket) do
    socket |> assign(filename: filename)
  end

  defp update_filename(socket) do
    socket |> assign(filename: nil)
  end

  defp update_page(%{assigns: %{tool: %{pages: [%{page: page} | _]}}} = socket)
       when not is_nil(page) do
    socket |> assign(page: page)
  end

  defp update_page(socket) do
    socket |> assign(page: nil)
  end

  @impl true
  def handle_event("save", %{"file_model" => %{"name" => name, "ref" => ref}}, socket) do
    {:noreply, socket |> handle_save(name, ref)}
  end

  @impl true
  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  def handle_save(
        %{assigns: %{page: nil, tool: %{auth_node: auth_node} = tool}} = socket,
        name,
        ref
      ) do
    file = Content.Public.prepare_file(name, ref)

    page =
      Content.Public.prepare_page(
        get_body(name, ref),
        Core.Authorization.prepare_node(auth_node)
      )

    result = Instruction.Public.add_file_and_page(tool, file, page)
    socket |> handle_result(result)
  end

  def handle_save(%{assigns: %{file: file, page: page, tool: tool}} = socket, name, ref) do
    file =
      Content.FileModel.changeset(file, %{name: name, ref: ref})
      |> Content.FileModel.validate()

    page =
      Content.PageModel.changeset(page, %{body: get_body(name, ref)})
      |> Content.PageModel.validate()

    result = Instruction.Public.update_file_and_page(tool, file, page)
    socket |> handle_result(result)
  end

  defp handle_result(socket, result) do
    case result do
      {:ok, %{content_file: file, content_page: page}} ->
        socket |> assign(file: file, page: page)

      {:error, :content_file, changeset, _} ->
        socket |> assign(changeset: changeset)
    end
  end

  defp get_body(name, url) do
    dgettext("eyra-instruction", "download_page.body", name: name, url: url)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Text.form_field_label id={"#{@id}_file.label"} ><%=dgettext("eyra-instruction", "download_form.file.label") %></Text.form_field_label>
        <.spacing value="XXS" />
        <.file_selector
          id="file"
          uploads={@uploads}
          filename={@filename}
          placeholder={dgettext("eyra-instruction", "download_form.file.placeholder")}
          select_button={dgettext("eyra-instruction", "download_form.file.select.button")}
          replace_button={dgettext("eyra-instruction", "download_form.file.replace.button")}
          />
      </div>
    """
  end
end
