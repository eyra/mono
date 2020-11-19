defmodule GreenLight.Loaders do
  @moduledoc """
  This is module that automates the loading of entities based on path parameters.

  It is used by the authorization system to enforce access permissions against
  the loaded entities.
  """

  def init(conf), do: conf

  def call(%Plug.Conn{} = conn, {loader, parent}) do
    params = conn.path_params

    {key, entity} = loader.(conn, params, parent)

    entities = Map.get(conn.private, :greenlight_entities, []) ++ [entity]

    conn
    |> Plug.Conn.assign(key, entity)
    |> Plug.Conn.put_private(:greenlight_entities, entities)
  end

  def entities(%Plug.Conn{} = conn) do
    conn.private.greenlight_entities
  end

  def load_entities(loaders, %Plug.Conn{path_params: path_params} = conn) do
    {entities, conn} =
      loaders
      |> Enum.reverse()
      |> Enum.map_reduce(conn, fn {loader, as_parent}, conn ->
        {key, entity} = loader.(conn, path_params, as_parent)

        {entity,
         conn
         |> Plug.Conn.assign(key, entity)}
      end)

    {entities,
     conn
     |> Plug.Conn.put_private(:greenlight_entities, entities)}
  end

  defmacro entity_loader(loader, opts \\ []) do
    quote do
      Module.register_attribute(__MODULE__, :entity_loaders, accumulate: true)

      for parent_loader <- Keyword.get(unquote(opts), :parents, []) do
        @entity_loaders {parent_loader, true}
      end

      @entity_loaders {unquote(loader), false}

      def load_entities(%Plug.Conn{path_params: path_params} = conn),
        do: unquote(__MODULE__).load_entities(@entity_loaders, conn)
    end
  end

  @doc false
  defmacro __using__([]) do
    quote do
      import unquote(__MODULE__), only: [entity_loader: 1, entity_loader: 2]
    end
  end

  # @doc """
  # Check if the specified `action` on the current controller (automatically
  # detected) is available for the user associated with the `conn`. An example of
  # it's usage:

  #       <%= if can?(@conn, :show, study) do %>
  #       <span><%= button "Show", method: :get, to: Routes.study_path(@conn, :show, study) %></span>
  #       <% end %>
  # """

  # def can?(conn, action, entity \\ nil) do
  #   permission = conn.private.phoenix_controller |> controller_to_permission(action)
  #   GreenLight.allowed?(conn, permission, entity)
  # end

  # @doc false
  # def view do
  #   quote do
  #     import unquote(__MODULE__), only: [can?: 3]
  #   end
  # end
end
