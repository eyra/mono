defmodule CoreWeb.Live.Hook.Inject do
  def on_mount(_live_view_module, _params, session, socket) do
    session
    |> Map.get("need", %{})
    |> Enum.each(fn {key, value} -> Frameworks.Need.inject(key, value) end)

    {:cont, socket}
  end
end
