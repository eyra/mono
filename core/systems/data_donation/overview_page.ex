defmodule Systems.DataDonation.OverviewPage do
  @moduledoc """
   The recruitment page for researchers.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :studies

  import CoreWeb.Layouts.Workspace.Component
  import Frameworks.Pixel.Form

  alias Systems.DataDonation.TaskModel

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      %TaskModel{}
      |> TaskModel.changeset(%{})

    {
      :ok,
      socket
      |> assign(changeset: changeset)
    }
  end

  @impl true
  def handle_event("submit", _model, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="port-studies" phx-hook="LiveContent">
      <.workspace title="Studies" menus={@menus}>
        <Area.content>
          <Margin.y id={:page_top} />
          <.form id={:main_form} :let={form} for={@changeset} phx-submit="submit" >
            <.text_input form={form} field={:title} label_text="Title" />
            <.text_input form={form} field={:subtitle} label_text="Subtitle" />
          </.form>
        </Area.content>
      </.workspace>
    </div>
    """
  end
end
