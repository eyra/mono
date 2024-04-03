defmodule Systems.Graphite.SubmissionListForm do
  use CoreWeb, :live_component

  alias Systems.Graphite

  @impl true
  def update(%{action: :close}, socket) do
    send(self(), {:hide_popup})

    {
      :ok,
      socket
      |> update_vm()
    }
  end

  @impl true
  def update(%{id: id, active?: active?}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        active?: active?
      )
      |> update_vm()
    }
  end

  defp update_vm(socket) do
    # TODO: PreRef
    socket
  end

  @impl true
  def handle_event("add", _params, socket) do
    # popup = %{
    #   id: :submission_form,
    #   module: Graphite.SubmissionForm,
    #   spot: spot,
    #   submission: %Graphite.SubmissionModel{},
    #   parent: %{type: __MODULE__, id: id}
    # }

    # send(self(), {:show_popup, popup})

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event(
        "edit",
        %{"item" => _item_id},
        socket
      ) do
    # if submission = Enum.find(submissions, &(&1.id == String.to_integer(item_id))) do
    #   popup = %{
    #     id: :submission_form,
    #     module: Graphite.SubmissionForm,
    #     spot: spot,
    #     submission: submission,
    #     parent: %{type: __MODULE__, id: id}
    #   }

    #   send(self(), {:show_popup, popup})
    # end

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event(
        "remove",
        %{"item" => _item_id},
        socket
      ) do
    # if submission = Enum.find(submissions, &(&1.id == String.to_integer(item_id))) do
    #   Graphite.Public.delete(submission)
    # end

    {
      :noreply,
      socket
      |> update_vm()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title2><%= @vm.title %></Text.title2>
      <Text.intro margin="mb-4 lg:mb-6"><%= @vm.intro %></Text.intro>
      <Text.sub_head><%= @vm.subhead %></Text.sub_head>
      <.spacing value="M" />

      <Graphite.SubmissionView.list items={@vm.items} />

      <%= if @vm.add_button do %>
        <.spacing value="M" />
        <.wrap>
          <Button.dynamic {@vm.add_button} />
        </.wrap>
      <% end %>
    </div>
    """
  end
end
