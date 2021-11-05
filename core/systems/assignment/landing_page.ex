defmodule Systems.Assignment.LandingPage do
  @moduledoc """
  The  page for an assigned task
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :assignment

  alias EyraUI.Text.{Title1, Title3, BodyLarge}
  alias EyraUI.Card.Highlight

  alias CoreWeb.UI.Navigation.ButtonBar

  alias Systems.{
    Assignment
  }

  data(model, :map)
  data(task, :map)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Assignment.Context.get!(id, [:crew]).crew
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    model = Assignment.Context.get!(id, [:crew])

    {
      :ok,
      socket
      |> assign(model: model)
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
  def handle_event("withdraw", _params,
    %{
      assigns: %{
        model: model,
        vm: %{withdraw_redirect: withdraw_redirect}
      }
    } = socket
  ) do
    {:noreply, socket |> withdraw_redirect.handle.(withdraw_redirect, model)}
  end

  defp grid_cols(1), do: "grid-cols-1 sm:grid-cols-1"
  defp grid_cols(2), do: "grid-cols-1 sm:grid-cols-2"
  defp grid_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  defp action_map(%{vm: %{call_to_action: %{label: label}}}) do
    %{
      call_to_action: %{
        action: %{type: :send, event: "call-to-action"},
        face: %{
          type: :primary,
          label: label
        }
      },
      withdraw: %{
        action: %{type: :send, event: "withdraw"},
        face: %{
          type: :secondary,
          label: dgettext("eyra-crew", "withdraw.button"),
          text_color: "text-delete",
          border_color: "border-delete"
        }
      },
    }
  end

  defp create_actions(%{vm: %{completed?: completed?}} = assigns) do
    create_actions(action_map(assigns), completed?)
  end

  defp create_actions(%{call_to_action: call_to_action, withdraw: withdraw}, false), do: [call_to_action, withdraw]
  defp create_actions(%{call_to_action: call_to_action}, true), do: [call_to_action]

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ @vm.hero_title }}
      menus={{ @menus }}
    >
      <ContentArea>
        <MarginY id={{:page_top}} />
        <div class="grid gap-6 sm:gap-8 {{ grid_cols(Enum.count(@vm.highlights)) }}">
          <div :for={{ highlight <- @vm.highlights }} class="bg-grey5 rounded">
            <Highlight title={{highlight.title}} text={{highlight.text}} />
          </div>
        </div>
        <Spacing value="L" />
        <Title1>{{@vm.title}}</Title1>
        <Spacing value="M" />
        <Title3>{{@vm.subtitle}}</Title3>
        <Spacing value="M" />
        <BodyLarge>{{@vm.text}}</BodyLarge>
        <Spacing value="L" />

        <MarginY id={{:button_bar_top}} />
        <ButtonBar buttons={{create_actions(assigns)}} />
      </ContentArea>
    </Workspace>
    """
  end
end
