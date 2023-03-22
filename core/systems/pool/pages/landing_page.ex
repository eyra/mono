defmodule Systems.Pool.LandingPage do
  @moduledoc """
   The pool details screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pool_landing

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias Frameworks.Pixel.Text

  alias Systems.{
    Pool
  }

  data(title, :string, default: "title")
  data(description, :string, default: "description")
  data(participant?, :boolean)
  data(buttons, :list)

  @impl true
  def mount(%{"id" => pool_id}, _session, socket) do
    pool_id = String.to_integer(pool_id)
    pool = Pool.Public.get!(pool_id)
    title = Pool.Model.title(pool)

    {
      :ok,
      socket
      |> assign(
        id: pool_id,
        pool: pool,
        title: title
      )
      |> update_membership()
      |> update_description()
      |> update_buttons()
      |> update_menus()
    }
  end

  defp update_membership(%{assigns: %{pool: pool, current_user: user}} = socket) do
    socket |> assign(participant?: Pool.Public.is_participant?(pool, user))
  end

  defp update_description(%{assigns: %{participant?: participant?}} = socket) do
    description =
      if participant? do
        dgettext("eyra-pool", "landing.description.participant")
      else
        dgettext("eyra-pool", "landing.description.visitor")
      end

    socket |> assign(description: description)
  end

  defp update_buttons(%{assigns: %{participant?: true}} = socket) do
    buttons = [
      %{
        action: %{type: :send, event: "unregister"},
        face: %{type: :primary, label: dgettext("eyra-pool", "landing.unregister.button")}
      }
    ]

    socket |> assign(buttons: buttons)
  end

  defp update_buttons(%{assigns: %{participant?: false}} = socket) do
    buttons = [
      %{
        action: %{type: :send, event: "register"},
        face: %{type: :primary, label: dgettext("eyra-pool", "landing.register.button")}
      }
    ]

    socket |> assign(buttons: buttons)
  end

  @impl true
  def handle_event("register", _, socket) do
    {
      :noreply,
      socket
      |> register()
      |> update_membership()
      |> update_description()
      |> update_buttons()
    }
  end

  @impl true
  def handle_event("unregister", _, socket) do
    {
      :noreply,
      socket
      |> unregister()
      |> update_membership()
      |> update_description()
      |> update_buttons()
    }
  end

  defp register(%{assigns: %{pool: pool, current_user: user}} = socket) do
    Pool.Public.link!(pool, user)
    socket
  end

  defp unregister(%{assigns: %{pool: pool, current_user: user}} = socket) do
    Pool.Public.unlink!(pool, user)
    socket
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("eyra-pool", "landing.title")} menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <Text.Title2>{@title}</Text.Title2>
        <Text.Body>{@description}</Text.Body>

        <Spacing value="M" />
        <div class="flex flex-row gap-4">
          <DynamicButton :for={button <- @buttons} vm={button} />
        </div>
      </ContentArea>
    </Workspace>
    """
  end
end
