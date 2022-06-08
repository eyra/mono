defmodule CoreWeb.UrlResolver do
  @doc """
  The `url_resolver` function creates a anonymous function that can be used to
  create URL's. It wraps the Phoenix router and binds the given socket. This
  allows it to be passed into code that does not depend the whole of Phoenix
  but needs to generate URLs.
  """
  def url_resolver(socket) do
    fn view, args -> resolve(socket, view, args) end
  end

  defp resolve(socket, view, args) when is_integer(args) do
    CoreWeb.Router.Helpers.live_path(socket, view, args)
  end

  defp resolve(socket, view, args) do
    case Keyword.pop(args, :id) do
      {nil, args} -> CoreWeb.Router.Helpers.live_path(socket, view, args)
      {id, args} -> CoreWeb.Router.Helpers.live_path(socket, view, id, args)
    end
  end
end
