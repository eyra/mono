defmodule Systems.Instruction.GeneralForm do
  use CoreWeb, :live_component

  import CoreWeb.Gettext

  alias Systems.Content
  alias Systems.Instruction

  @impl true
  def update(%{id: id, entity: tool}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        tool: tool
      )
      |> ensure_page()
      |> compose_child(:page_form)
    }
  end

  @impl true
  def compose(:page_form, %{tool: %{pages: [%{page: content_page}]}}) do
    %{
      module: Content.PageForm,
      params: %{
        entity: content_page
      }
    }
  end

  defp ensure_page(%{assigns: %{tool: %{pages: [_]}}} = socket), do: socket

  defp ensure_page(%{assigns: %{tool: %{auth_node: auth_node, pages: []} = tool}} = socket) do
    content_page = Content.Public.prepare_page("", Core.Authorization.prepare_node(auth_node))

    page =
      %Instruction.PageModel{}
      |> Instruction.PageModel.changeset(%{})
      |> Ecto.Changeset.put_assoc(:page, content_page)

    changeset =
      tool
      |> Instruction.ToolModel.changeset(%{})
      |> Ecto.Changeset.put_assoc(:pages, [page])

    {:ok, tool} = Core.Persister.save(tool, changeset)

    assign(socket, tool: tool)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Text.form_field_label id={"#{@id}_file.label"} ><%=dgettext("eyra-instruction", "general_form.file.label") %></Text.form_field_label>
        <.spacing value="XXS" />
        <.child name={:page_form} fabric={@fabric} />
      </div>
    """
  end
end
