defmodule Systems.Lab.CheckInView do
  use CoreWeb.UI.LiveComponent
  import CoreWeb.Gettext
  require Logger

  alias Core.Accounts
  alias Systems.Director
  alias Frameworks.Pixel.Form.{Form, NumberInput}
  alias Frameworks.Pixel.Panel.Panel
  alias Frameworks.Pixel.Text.{BodyMedium, Title3}

  alias Systems.{
    Lab
  }

  prop(tool, :map, required: true)
  prop(parent, :any, required: true)

  data(changeset, :map)
  data(subject, :map)
  data(query, :string)
  data(focus, :string, default: "")

  def update(%{id: id, tool: tool, parent: parent}, socket) do
    changeset =
      %Lab.CheckInModel{}
      |> Lab.CheckInModel.changeset(:init, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        tool: tool,
        parent: parent,
        changeset: changeset,
        query: nil,
        subject: nil
      )
      |> update_ui()
    }
  end

  defp update_ui(socket) do
    socket
  end

  @impl true
  def handle_event(
        "accept",
        _,
        %{assigns: %{tool: tool, parent: parent, subject: %{user_id: user_id}}} = socket
      ) do
    Director.context(tool).activate_task(tool, user_id)
    update_target(parent, %{checkin: :new_participant})
    {:noreply, socket |> assign(focus: "", query: nil, subject: nil)}
  end

  @impl true
  def handle_event(
        "update",
        %{"check_in_model" => %{"query" => ""}},
        socket
      ) do
    {:noreply, socket |> assign(query: nil, subject: nil)}
  end

  @impl true
  def handle_event(
        "update",
        %{"check_in_model" => %{"query" => query}},
        %{assigns: %{tool: tool, myself: myself}} = socket
      ) do
    public_id = String.to_integer(query)

    subject =
      Director.context(tool).search_subject(tool, public_id)
      |> to_view_model(tool, myself)

    {:noreply, socket |> assign(query: query, subject: subject)}
  end

  @impl true
  def handle_event("focus", %{"field" => field}, socket) do
    {:noreply, socket |> assign(focus: field)}
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    {:noreply, socket |> assign(focus: "")}
  end

  @impl true
  def render(assigns) do
    ~F"""
      <div phx-click="reset_focus" phx-target={@myself}>
        <Panel bg_color="bg-grey1">
          <Title3 color="text-white">{dgettext("link-lab", "search.subject.title")}</Title3>
          <Spacing value="M" />
          <BodyMedium color="text-white">{dgettext("link-lab", "search.subject.body")}</BodyMedium>
          <Spacing value="S" />

          <Form id="search_subject" changeset={@changeset} change_event="update" submit="submit" target={@myself} focus={@focus}>
            <div class="w-44">
              <NumberInput field={:query} label_text={dgettext("link-lab", "search.subject.query.label")} reserve_error_space={false} debounce="300" background={:dark} label_color="text-white"/>
            </div>
            <div :if={@query != nil}>
              <div :if={@subject != nil}>
                <Spacing value="S"/>
                <div class="flex flex-row gap-8 sm:items-center">
                  <div class="font-body text-bodymedium sm:text-bodylarge flex-wrap text-white">
                    Subject {@subject.public_id}
                  </div>
                  <div class="font-body text-bodysmall sm:text-bodymedium text-white" >
                    <span class="whitespace-pre-wrap">{@subject.message}</span>
                  </div>
                  <div class="flex-wrap flex-shrink-0">
                    <div class="flex flex-row gap-4">
                      <DynamicButton :for={button <- @subject.buttons} vm={button} />
                    </div>
                  </div>
                </div>
              </div>
              <div :if={@subject == nil}>
                <div class="text-caption font-caption text-tertiary">
                  {dgettext("link-lab", "search.subject.not.found")}
                </div>
              </div>
            </div>
          </Form>
        </Panel>
      </div>
    """
  end

  defp to_view_model(nil, _tool, _target), do: nil

  defp to_view_model(
         %{
           user_id: user_id,
           public_id: public_id,
           expired: expired?
         },
         tool,
         target
       ) do
    message =
      if expired? do
        label = dgettext("link-lab", "search.subject.expired")
        "🚫  #{label}"
      else
        label =
          time_slot(tool, user_id)
          |> time_slot_label()

        "🗓  #{label}"
      end

    buttons =
      if expired? do
        []
      else
        [accept_button(target)]
      end

    %{
      user_id: user_id,
      public_id: public_id,
      message: message,
      buttons: buttons
    }
  end

  defp time_slot(tool, user_id) do
    user = Accounts.get_user!(user_id)
    %{time_slot_id: time_slot_id} = Lab.Context.reservation_for_user(tool, user)
    Lab.Context.get_time_slot(time_slot_id)
  end

  defp time_slot_label(%{start_time: start_time, location: location}) do
    date =
      start_time
      |> CoreWeb.UI.Timestamp.to_date()
      |> CoreWeb.UI.Timestamp.humanize_date()

    time =
      start_time
      |> CoreWeb.UI.Timestamp.humanize_time()

    "#{date}  |  #{time}  |  #{location}" |> Macro.camelize()
  end

  defp accept_button(target) do
    %{
      action: %{type: :send, target: target, event: "accept"},
      face: %{
        type: :icon,
        icon: :add,
        color: :tertiary,
        label: dgettext("link-lab", "search.subject.accept.button")
      }
    }
  end
end
