defmodule Systems.Assignment.LandingPage do
  @moduledoc """
  The  page for an assigned task
  """
  use CoreWeb, :live_view
  use CoreWeb.UI.PlainDialog
  use CoreWeb.Layouts.Workspace.Component, :assignment

  alias Frameworks.Pixel.Text.{Title1, Title3, BodyLarge}
  alias Frameworks.Pixel.Card.Highlight
  alias Frameworks.Pixel.Panel.Panel
  alias Frameworks.Pixel.Wrap

  alias CoreWeb.UI.Navigation.ButtonBar
  alias Core.Accounts

  alias Systems.{
    Assignment,
    NextAction
  }

  data(model, :map)
  data(task, :map)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Assignment.Context.get!(id, [:crew]).crew
  end

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    NextAction.Context.clear_next_action(user, Assignment.CheckRejection, key: "#{id}", params: %{id: id})

    model = Assignment.Context.get!(id, [:crew])

    {
      :ok,
      socket
      |> assign(
        model: model,
        dialog: nil
      )
      |> observe_view_model()
      |> update_menus()
    }
  end

  defoverridable handle_view_model_updated: 1
  def handle_view_model_updated(socket) do
    socket
    |> update_menus()
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    title = String.capitalize(dgettext("eyra-assignment", "cancel.confirm.title"))
    text = String.capitalize(dgettext("eyra-assignment", "cancel.confirm.text"))
    confirm_label = dgettext("eyra-assignment", "cancel.confirm.label")

    {:noreply, socket |> confirm("cancel", title, text, confirm_label)}
  end

  @impl true
  def handle_event("cancel_confirm", _params, %{assigns: %{current_user: user, model: %{id: id}}} = socket) do
    Assignment.Context.cancel(id, user)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Accounts.start_page_target(user)))}
  end

  @impl true
  def handle_event("cancel_cancel", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  @impl true
  def handle_event("call-to-action", _params,
    %{
      assigns: %{
        model: model,
        vm: %{call_to_action: call_to_action}
      }
    } = socket
  ) do
    {:noreply, socket |> call_to_action.handle.(call_to_action, model)}
  end

  @impl true
  def handle_event("inform_ok", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  defp action_map(%{model: assignment, vm: %{
    public_id: public_id,
    title: title,
    contact_enabled?: contact_enabled?,
    call_to_action: %{label: label}
  }}) do

    actions = %{
      call_to_action: %{
        action: %{type: :send, event: "call-to-action"},
        face: %{
          type: :primary,
          label: label
        }
      }
    }

    {:ok, %{email: email}} = Assignment.Context.owner(assignment)
    if contact_enabled? and email do
      actions
      |> Map.put(:contact, %{
        action: %{type: :href, href: contact_href(email, title, public_id)},
        face: %{type: :label, label: dgettext("eyra-assignment", "contact.button")}
      })
    else
      actions
    end
  end

  defp contact_href(email, title, nil) do
    "mailto:#{email}?subject=#{title}"
  end

  defp contact_href(email, title, public_id) do
    "mailto:#{email}?subject=[panl_id=#{public_id}] #{title}"
  end

  defp cancel_button() do
    %{
      action: %{type: :send, event: "cancel"},
      face: %{type: :secondary, text_color: "text-delete", label: dgettext("eyra-assignment", "cancel.button")}
    }
  end

  defp create_actions(%{call_to_action: call_to_action, contact: contact}), do: [call_to_action, contact]
  defp create_actions(%{call_to_action: call_to_action}), do: [call_to_action]

  defp show_dialog?(nil), do: false
  defp show_dialog?(_), do: true

  defp grid_cols(1), do: "grid-cols-1 sm:grid-cols-1"
  defp grid_cols(2), do: "grid-cols-1 sm:grid-cols-2"
  defp grid_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  def render(assigns) do
    ~F"""
    <Workspace
      title={@vm.hero_title}
      menus={@menus}
    >
      <div :if={show_dialog?(@dialog)} class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
        <div class="flex flex-row items-center justify-center w-full h-full">
          <PlainDialog vm={@dialog} />
        </div>
      </div>

      <ContentArea>
        <MarginY id={:page_top} />
        <Title1>{@vm.title}<span class="text-primary"> #{@vm.public_id}</span></Title1>
        <Spacing value="L" />

        <div class={"grid gap-6 sm:gap-8 #{grid_cols(Enum.count(@vm.highlights))}"}>
          <div :for={highlight <- @vm.highlights} class="bg-grey5 rounded">
            <Highlight title={highlight.title} text={highlight.text} />
          </div>
        </div>
        <Spacing value="L" />

        <Title3>{@vm.subtitle}</Title3>
        <Spacing value="M" />
        <BodyLarge>{@vm.text}</BodyLarge>
        <Spacing value="L" />

        <MarginY id={:button_bar_top} />
        <ButtonBar buttons={create_actions(action_map(assigns))} />
        <Spacing value="XL" />

        <Panel :if={Map.get(@vm, :cancel_enabled?, false)}>
          <#template slot="title">
            <Title3>{dgettext("eyra-assignment", "cancel.title")}</Title3>
          </#template>
          <Spacing value="M" />
          <BodyLarge>{dgettext("eyra-assignment", "cancel.text")}</BodyLarge>
          <Spacing value="M" />
          <Wrap>
            <DynamicButton vm={cancel_button()} />
          </Wrap>
        </Panel>

      </ContentArea>
    </Workspace>
    """
  end
end
