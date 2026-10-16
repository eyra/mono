defmodule Core do
  @moduledoc """
  Core keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc """
  Mica's own systems (`Core.System`), the start of every `c:Core.SaaS.systems/0`.
  Routes are spliced in this order. Keep it a literal list.
  """
  def systems do
    [
      Systems.Admin.System,
      Systems.Advert.System,
      Systems.Affiliate.System,
      Systems.Alliance.System,
      Systems.Assignment.System,
      Systems.Fund.System,
      Systems.Desktop.System,
      Systems.Document.System,
      Systems.Feldspar.System,
      Systems.Home.System,
      Systems.Lab.System,
      Systems.Manual.System,
      Systems.NextAction.System,
      Systems.Payment.System,
      Systems.Org.System,
      Systems.Pool.System,
      Systems.Project.System,
      Systems.Promotion.System,
      Systems.Storage.System,
      Systems.Support.System,
      Systems.Account.System
    ]
  end

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
