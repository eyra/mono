defmodule Systems.Org.NodeView do
  use CoreWeb, :embedded_live_view
  use CoreWeb.Live.FlashHelpers

  alias Core.Repo
  alias Frameworks.Pixel.Text
  alias Systems.Content
  alias Systems.Org

  import Content.TextBundleInput
  import Frameworks.Pixel.Form

  def dependencies(), do: [:node_id, :is_admin?]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{node_id: node_id}}) do
    Org.Public.get_node!(node_id, Org.NodeModel.preload_graph(:full))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"node_model" => attrs}, %{assigns: %{model: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  defp save(socket, entity, attrs) do
    changeset = Org.NodeModel.changeset(entity, attrs)

    socket
    |> hide_flash()
    |> do_save(changeset)
  end

  defp do_save(socket, changeset) do
    case Repo.update(changeset) do
      {:ok, updated_entity} ->
        socket
        |> assign(model: updated_entity)
        |> update_view_model()
        |> flash_persister_saved()

      {:error, changeset} ->
        socket
        |> assign(changeset: changeset)
        |> flash_error()
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Text.title2><%= dgettext("eyra-org", "node.title") %></Text.title2>
      <.form id="node_form" :let={form} for={@vm.changeset} phx-change="save">
        <.text_bundle_input form={form} field={:full_name_bundle} show_locale={false} label_text={dgettext("eyra-org", "full.name.title")} />
        <.spacing value="XS" />

        <.text_bundle_input form={form} field={:short_name_bundle} show_locale={false} label_text={dgettext("eyra-org", "short.name.title")} />

        <%= if @vm.is_admin? do %>
          <.spacing value="XS" />
          <.text_input form={form} field={:identifier_string} label_text={dgettext("eyra-org", "identifier.label")} />
          <.spacing value="XS" />

          <.text_input form={form} field={:domains_string} label_text={dgettext("eyra-org", "domains.label")} />
        <% end %>
      </.form>
      </Area.content>
    </div>
    """
  end
end
