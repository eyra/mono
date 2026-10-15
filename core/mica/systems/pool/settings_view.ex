defmodule Systems.Pool.SettingsView do
  @moduledoc """
  Embedded LiveView for the Settings tab on the Pool Admin page.

  Lets a pool admin edit name and icon. Currency is shown read-only —
  changing it post-creation would break bookkeeping. Replaces the
  Citizen.Pool.Form modal for the cases this tab covers.
  """
  use CoreWeb, :embedded_live_view
  use CoreWeb.Live.FlashHelpers

  alias Frameworks.Pixel.Text
  alias Systems.Pool

  import Frameworks.Pixel.Form

  def dependencies(), do: [:pool_id]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{pool_id: pool_id}}) do
    Pool.Public.get!(pool_id)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_event("save", %{"model" => attrs}, %{assigns: %{model: pool}} = socket) do
    {:noreply, save(socket, pool, attrs)}
  end

  defp save(socket, pool, attrs) do
    changeset = Pool.Model.change(pool, attrs)

    case Core.Persister.save(pool, changeset) do
      {:ok, updated_pool} ->
        socket
        |> assign(model: updated_pool)
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
    <div data-testid="pool-settings-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-pool", "settings.title") %></Text.title2>
        <.spacing value="S" />

        <.form id="pool_settings_form" :let={form} for={@vm.changeset} phx-change="save">
          <.text_input
            form={form}
            field={:name}
            label_text={dgettext("eyra-pool", "settings.name.label")}
          />
          <.spacing value="XS" />

          <.text_input
            form={form}
            field={:virtual_icon}
            maxlength="2"
            label_text={dgettext("eyra-pool", "settings.icon.label")}
          />
        </.form>
      </Area.content>
    </div>
    """
  end
end
