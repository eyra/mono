defmodule Systems.Org.NodeView do
  use MicaWeb, :embedded_live_view
  use MicaWeb.Live.FlashHelpers

  alias Frameworks.Pixel
  alias Frameworks.Pixel.Text
  alias Systems.Admin
  alias Systems.Content
  alias Systems.Org

  import Content.TextBundleInput
  import Frameworks.Pixel.Form

  def dependencies(), do: [:node_id, :is_admin?, :current_user]

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

  @impl true
  def handle_event(
        "toggle_research_institute",
        _,
        %{assigns: %{model: org, current_user: user}} = socket
      ) do
    case Org.Public.mark_research_institute(org, not Org.NodeModel.research_institute?(org), user) do
      {:ok, org} ->
        {:noreply, socket |> assign(model: org) |> update_view_model() |> flash_persister_saved()}

      {:error, _} ->
        {:noreply, socket |> update_view_model() |> flash_error()}
    end
  end

  # Identifier and domains decide who joins as a member, so only system admins
  # change them; everyone else who can manage the organisation changes its names.
  defp changeset(entity, attrs, user) do
    if Admin.Public.admin?(user) do
      Org.NodeModel.changeset(entity, attrs)
    else
      Org.NodeModel.names_changeset(entity, attrs)
    end
  end

  # The page may have been opened before the user lost the right to manage
  # the organisation, so the right is checked again on every save.
  defp save(%{assigns: %{current_user: user}} = socket, entity, attrs) do
    if Org.Public.can_manage?(entity, user) do
      persist(socket, entity, changeset(entity, attrs, user))
    else
      socket
      |> hide_flash()
      |> flash_error(dgettext("eyra-org", "node.save.not.allowed"))
    end
  end

  defp persist(socket, entity, changeset) do
    case Mica.Persister.save(entity, changeset) do
      {:ok, updated_entity} ->
        socket
        |> hide_flash()
        |> assign(model: updated_entity, changeset: nil)
        |> update_view_model()
        |> flash_persister_saved()

      {:error, changeset} ->
        socket
        |> hide_flash()
        |> assign(changeset: %{changeset | action: :update})
        |> update_view_model()
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
      <%= if @vm.is_admin? do %>
        <.spacing value="S" />
        <label class="flex flex-row gap-3 items-center cursor-pointer w-fit">
          <Pixel.checkbox
            checked={@vm.research_institute?}
            phx-click="toggle_research_institute"
            data-testid="research-institute-checkbox"
          />
          <Text.label><%= dgettext("eyra-org", "research.institute.label") %></Text.label>
        </label>
        <%= if @vm.research_institute_note do %>
          <.spacing value="XXS" />
          <div data-testid="research-institute-note">
            <Text.body_small color="text-grey2"><%= @vm.research_institute_note %></Text.body_small>
          </div>
        <% end %>
      <% end %>
      </Area.content>
    </div>
    """
  end
end
