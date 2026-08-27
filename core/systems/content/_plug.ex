defmodule Systems.Content.Plug do
  @moduledoc false
  @behaviour Plug

  alias Systems.Content.LocalFS

  defmacro setup() do
    quote do
      plug(Systems.Content.Plug, at: Systems.Content.LocalFS.public_path())
    end
  end

  @impl true
  def init(opts) do
    opts
    # Ensure that init works, from will be set dynamically later on
    |> Keyword.put(:from, {nil, nil})
    |> Plug.Static.init()
  end

  @impl true
  def call(conn, options) do
    call(Systems.Content.Private.get_backend(), conn, options)
  end

  def call(LocalFS, conn, options) do
    root_path = LocalFS.get_root_path()
    options = Map.put(options, :from, root_path)
    Plug.Static.call(conn, options)
  end

  def call(_, conn, _options), do: conn
end
