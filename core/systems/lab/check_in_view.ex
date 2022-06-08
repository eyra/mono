defmodule Systems.Lab.CheckInView do
  use CoreWeb.UI.LiveComponent
  import CoreWeb.Gettext
  require Logger

  alias Core.Accounts
  alias Systems.Director
  alias Frameworks.Pixel.Form.{Form, TextInput}
  alias Frameworks.Pixel.Panel.Panel
  alias Frameworks.Pixel.Text.{BodyMedium, Title3}

  alias Systems.{
    Lab
  }

  @max_search_results 5

  prop(tool, :map, required: true)
  prop(parent, :any, required: true)

  data(changeset, :map)
  data(items, :list, default: [])
  data(message, :string, default: "")
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
        query: nil
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
        %{"item" => user_id},
        %{assigns: %{tool: tool, parent: _parent}} = socket
      ) do
    user_id = String.to_integer(user_id)

    Director.context(tool).activate_task(tool, user_id, true)
    # update_target(parent, %{checkin: :new_participant})
    {:noreply, socket |> assign(focus: "", query: nil, message: nil)}
  end

  @impl true
  def handle_event(
        "update",
        %{"check_in_model" => %{"query" => ""}},
        socket
      ) do
    {:noreply, socket |> assign(query: nil, message: nil)}
  end

  @impl true
  def handle_event(
        "update",
        %{"check_in_model" => %{"query" => query}},
        %{assigns: %{tool: tool}} = socket
      ) do
    {items, message} =
      case Integer.parse(query) do
        {public_id, ""} -> search(public_id, tool)
        _ -> search(query, tool)
      end

    {:noreply, socket |> assign(query: query, items: items, message: message)}
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
  def handle_event("submit", _, socket) do
    {:noreply, socket}
  end

  defp search(public_id, tool) when is_integer(public_id) do
    item =
      Director.context(tool).search_subject(tool, public_id)
      |> to_view_model(tool)

    case item do
      nil -> {[], dgettext("link-lab", "search.subject.not.found")}
      vm -> {[vm], nil}
    end
  end

  defp search(query, tool) when is_binary(query) do
    items =
      Core.Accounts.search(query)
      |> Enum.map(&to_view_model(&1, tool))

    message =
      case Enum.count(items) do
        0 ->
          dgettext("link-lab", "search.email.not.found")

        count when count > @max_search_results ->
          dgettext("link-lab", "search.email.found.more", count: count, max: @max_search_results)

        count when count == 1 ->
          nil

        count ->
          dgettext("link-lab", "search.email.found", count: count)
      end

    {items |> Enum.take(@max_search_results), message}
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
            <div class="w-form">
              <TextInput field={:query} label_text={dgettext("link-lab", "search.subject.query.label")} reserve_error_space={false} debounce="300" background={:dark} label_color="text-white"/>
            </div>
            <div :if={@message}>
              <div class="text-caption font-caption text-tertiary">
                {@message}
              </div>
            </div>
            <div :if={@query}>
              <Spacing value="S" />
              <table>
                <Lab.CheckInItem :for={item <- @items} {...item} target={@myself}/>
              </table>
            </div>
          </Form>
        </Panel>
      </div>
    """
  end

  defp to_view_model(nil, _tool), do: nil
  defp to_view_model({nil, nil}, _tool), do: nil

  defp to_view_model(%Core.Accounts.User{id: user_id, email: email} = user, tool) do
    reservation = reservation(user, tool)
    time_slot = time_slot(reservation)

    search_result = Director.context(tool).search_subject(tool, user)

    status =
      case search_result do
        {_, task} -> item_status(task, reservation)
        _ -> :reservation_not_found
      end

    public_id =
      case search_result do
        {%{public_id: public_id}, _} -> public_id
        _ -> nil
      end

    check_in_date =
      case search_result do
        {_, %{completed_at: completed_at}} -> completed_at
        _ -> nil
      end

    %{
      id: user_id,
      email: email,
      status: status,
      subject: public_id,
      time_slot: time_slot,
      check_in_date: check_in_date
    }
  end

  defp to_view_model(
         {
           %{
             user_id: user_id,
             public_id: public_id
           } = _member,
           %{completed_at: completed_at} = task
         },
         tool
       ) do
    reservation = reservation(user_id, tool)
    time_slot = time_slot(reservation)
    status = item_status(task, reservation)

    %{
      id: user_id,
      subject: public_id,
      status: status,
      time_slot: time_slot,
      check_in_date: completed_at
    }
  end

  defp item_status(%{status: :completed} = _task, _reservation), do: :signed_up_already
  defp item_status(%{status: :rejected} = _task, _reservation), do: :signed_up_already
  defp item_status(%{status: :accepted} = _task, _reservation), do: :signed_up_already
  defp item_status(%{expired: true} = _task, _reservation), do: :reservation_expired
  defp item_status(_task, nil), do: :reservation_not_found
  defp item_status(_task, %{status: :cancelled}), do: :reservation_cancelled
  defp item_status(_task, reservation) when reservation != nil, do: :reservation_available

  defp reservation(user_id, tool) when is_integer(user_id) do
    user_id
    |> Accounts.get_user!()
    |> reservation(tool)
  end

  defp reservation(%Accounts.User{} = user, tool) do
    Lab.Context.reservation_for_user(tool, user)
  end

  defp time_slot(nil), do: nil

  defp time_slot(%{time_slot_id: time_slot_id} = _reservation) do
    Lab.Context.get_time_slot(time_slot_id)
  end
end
