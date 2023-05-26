defmodule Systems.DataDonation.ToolForm do
  use CoreWeb.LiveForm

  alias Core.Accounts

  alias CoreWeb.UI.Timestamp
  alias CoreWeb.Router.Helpers, as: Routes

  alias Frameworks.Pixel.Text
  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Panel

  alias Systems.{
    DataDonation
  }

  # Handle update from parent
  @impl true
  def update(
        %{validate?: validate?, active_field: active_field},
        %{assigns: %{entity: _}} = socket
      ) do
    {
      :ok,
      socket
      |> update_validate?(validate?)
      |> update_active_field(active_field)
    }
  end

  @impl true
  def update(
        %{id: id, entity_id: entity_id, validate?: validate?, active_field: active_field},
        socket
      ) do
    entity = DataDonation.Public.get_tool!(entity_id)
    donations = DataDonation.Public.list_donations(entity)
    changeset = DataDonation.ToolModel.changeset(entity, :mount, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        entity: entity,
        changeset: changeset,
        donations: donations,
        validate?: validate?,
        active_field: active_field
      )
    }
  end

  defp update_active_field(%{assigns: %{active_field: current}} = socket, new)
       when new != current do
    socket
    |> assign(active_field: new)
  end

  defp update_active_field(socket, _new), do: socket

  defp update_validate?(%{assigns: %{validate?: current}} = socket, new) when new != current do
    socket
    |> assign(validate?: new)
  end

  defp update_validate?(socket, _new), do: socket

  # Handle Events

  @impl true
  def handle_event("save", %{"tool" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{entity_id: entity_id, current_user: user}} = socket
      ) do
    DataDonation.Public.get_tool!(entity_id)
    |> DataDonation.Public.delete()

    {:noreply,
     push_redirect(socket, to: Routes.live_path(socket, Accounts.start_page_target(user)))}
  end

  # Saving
  def save(socket, %DataDonation.ToolModel{} = entity, type, attrs) do
    changeset = DataDonation.ToolModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
  end

  attr(:entity_id, :any, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <%= if Enum.count(@donations) > 0 do %>
        <Text.title2><%= dgettext("eyra-data-donation", "donations.title") %></Text.title2>
        <Panel.flat bg_color="bg-grey6">
          <%= for donation <- @donations do %>
            <div class="mb-2 w-full">
              <div class="flex flex-row w-full">
                <div class="flex-wrap text-grey1 text-bodymedium font-body mr-6">
                  Participant {donation.user_id}
                </div>
                <div class="flex-grow text-grey2 text-bodymedium font-body">
                  <%= dgettext("eyra-data-donation", "received.label") %> <%= Timestamp.humanize(donation.inserted_at) %>
                </div>
                <div class="flex-wrap">
                  <a
                    href="/"
                    class="text-primary text-bodymedium font-body hover:text-grey1 underline focus:outline-none"
                  >
                    <%= dgettext("eyra-data-donation", "download.button.label") %>
                  </a>
                </div>
              </div>
            </div>
          <% end %>
        </Panel.flat>
        <.spacing value="S" />
        <Button.primary to="/" label={dgettext("eyra-data-donation", "download.all.button.label")} />
        <.spacing value="XL" />
      <% end %>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <Text.title3><%= dgettext("eyra-data-donation", "script.title") %></Text.title3>
        <.text_area form={form} field={:script} label_text={dgettext("eyra-data-donation", "script.label")} active_field={@active_field} />
        <.spacing value="L" />

        <Text.title3><%= dgettext("eyra-data-donation", "reward.title") %></Text.title3>
        <.number_input form={form} field={:reward_value} label_text={dgettext("eyra-data-donation", "reward.label")} active_field={@active_field} />
        <.spacing value="L" />

        <Text.title3><%= dgettext("eyra-data-donation", "nrofsubjects.title") %></Text.title3>
        <.number_input
          form={form}
          field={:subject_count}
          label_text={dgettext("eyra-data-donation", "config.nrofsubjects.label")}
          active_field={@active_field}
        />
      </.form>
      <.spacing value="M" />
      <Button.secondary_live_view label={dgettext("eyra-data-donation", "delete.button")} event="delete" />
      </Area.content>
    </div>
    """
  end
end
