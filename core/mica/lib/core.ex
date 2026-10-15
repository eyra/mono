defmodule Core do
  @moduledoc """
  Core keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def auth do
    quote do
      def auth_module() do
        Application.get_env(:core, :greenlight_auth_module)
      end

      def print_auth_roles(term) do
        auth_module().print_roles(term)
      end
    end
  end

  def public do
    quote do
      unquote(auth())
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end
end
