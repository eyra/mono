defmodule NativeDemoWeb.ScreenLive.Index do
  use NativeDemoWeb, :live_view

  @palettes [
    ~w(320e0b 572a1a 83502d b67f3e eeb753),
    ~w(060606 0c2539 1a4d7b 377fcb 5ba8d1),
    ~w(651245 8b154e c61c5a ff3c6f ff627b)
  ]

  @impl true
  def mount(params, _session, socket) do
    nav_stack =
      nav_stack(params)
      |> apply_operation(params)

    [depth, modal_depth] = top_node(nav_stack)

    colors = Enum.at(@palettes, rem(modal_depth, @palettes |> Enum.count()))
    color_index = rem(depth, colors |> Enum.count())

    {:ok,
     socket
     |> assign(:color, colors |> Enum.at(color_index))
     |> assign(:push_nav_stack, nav_stack |> apply_operation(:push) |> Jason.encode!())
     |> assign(:pop_nav_stack, nav_stack |> apply_operation(:pop) |> Jason.encode!())
     |> assign(
       :push_modal_nav_stack,
       nav_stack |> apply_operation(:push_modal) |> Jason.encode!()
     )
     |> assign(:pop_modal_nav_stack, nav_stack |> apply_operation(:pop_modal) |> Jason.encode!())
     |> assign(:depth, depth)
     |> assign(:modal_depth, modal_depth)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => _id}, socket) do
    {:noreply, socket}
  end

  def nav_stack(params) do
    params |> Map.get("nav_stack", "[]") |> Jason.decode!()
  end

  def top_node([]), do: [0, 0]

  def top_node([[depth, modal_depth] | _]) do
    [depth, modal_depth]
  end

  def apply_operation(nav_stack, :push) do
    [depth, modal_depth] = top_node(nav_stack)
    [[depth + 1, modal_depth] | nav_stack]
  end

  def apply_operation([[depth, _] | nav_stack], :pop) when depth > 0 do
    nav_stack
  end

  def apply_operation(nav_stack, :push_modal) do
    [_, modal_depth] = top_node(nav_stack)
    [[0, modal_depth + 1] | nav_stack]
  end

  def apply_operation([[_, modal_depth] | _] = nav_stack, :pop_modal)
      when modal_depth > 0 do
    target_modal_depth = modal_depth - 1

    Enum.drop_while(nav_stack, fn [_, modal_depth] -> modal_depth > target_modal_depth end)
  end

  def apply_operation(nav_stack, _) do
    nav_stack
  end
end
