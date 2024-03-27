defmodule Systems.Instruction.ForkForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  import CoreWeb.Gettext

  alias Systems.Instruction
  alias Systems.Content

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
      |> update_repository()
      |> update_changeset()
    }
  end

  defp update_repository(%{assigns: %{tool: %{assets: [%{repository: repository} | _]}}} = socket)
       when not is_nil(repository) do
    socket |> assign(repository: repository)
  end

  defp update_repository(socket) do
    socket |> assign(repository: %Content.RepositoryModel{})
  end

  defp update_changeset(%{assigns: %{repository: repository}} = socket) do
    changeset = Content.RepositoryModel.changeset(repository)
    socket |> assign(changeset: changeset)
  end

  defp update_page(%{assigns: %{tool: %{pages: [%{page: page} | _]}}} = socket)
       when not is_nil(page) do
    socket |> assign(page: page)
  end

  defp update_page(socket) do
    socket |> assign(page: nil)
  end

  @impl true
  def handle_event("save", %{"repository_model" => %{"url" => url}}, socket) do
    {:noreply, socket |> handle_save(url)}
  end

  def handle_save(%{assigns: %{page: nil, tool: %{auth_node: auth_node} = tool}} = socket, url) do
    repository = Content.Public.prepare_repository(%{platform: :github, url: url})

    page =
      Content.Public.prepare_page(
        dgettext("eyra-instruction", "fork_page.body", url: url),
        Core.Authorization.prepare_node(auth_node)
      )

    result = Instruction.Public.add_repository_and_page(tool, repository, page)
    socket |> handle_result(result)
  end

  def handle_save(%{assigns: %{repository: repository, page: page, tool: tool}} = socket, url) do
    repository =
      Content.RepositoryModel.changeset(repository, %{url: url})
      |> Content.RepositoryModel.validate()

    page =
      Content.PageModel.changeset(page, %{
        body: dgettext("eyra-instruction", "fork_page.body", url: url)
      })
      |> Content.PageModel.validate()

    result = Instruction.Public.update_repository_and_page(tool, repository, page)
    socket |> handle_result(result)
  end

  defp handle_result(socket, result) do
    case result do
      {:ok, %{content_repository: repository, content_page: page}} ->
        socket |> assign(repository: repository, page: page)

      {:error, :content_repository, changeset, _} ->
        socket |> assign(changeset: changeset)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="fork_content" phx-hook="LiveContent" data-show-errors={true}>
      <.form id={"#{@id}_fork"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input
          form={form}
          field={:url}
          placeholder={dgettext("eyra-instruction", "repository_url.placeholder")}
          label_text={dgettext("eyra-instruction", "repository_url.label")}
        />
      </.form>
    </div>
    """
  end
end
