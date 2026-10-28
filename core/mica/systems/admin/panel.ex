defmodule Systems.Admin.Panel do
  @moduledoc """
  A tab on the Admin page (`/admin/config`), with an embedded live view.

  Systems contribute panels with `c:Core.System.admin_panels/0`; the page shows
  them in `c:Core.SaaS.systems/0` order.

      defmodule Systems.Admin.ActionsPanel do
        use Systems.Admin.Panel
        use Gettext, backend: CoreWeb.Gettext

        @impl true
        def id, do: :actions

        @impl true
        def title, do: dgettext("eyra-admin", "actions.title")

        @impl true
        def audience, do: :admin

        @impl true
        def live_view, do: Systems.Admin.ActionsView
      end

  The audience says who sees the panel: `:admin` only system admins,
  `:org_admin` also admins of an organisation. System admins see every panel.
  """

  alias Frameworks.Concept.LiveContext

  @type audience :: :admin | :org_admin
  @type live_context :: %LiveContext{data: map()}
  @type viewer :: :admin | :org_admin

  @doc "The tab id. The live view's element id is `admin_<id>_view`."
  @callback id() :: atom()

  @callback title() :: String.t()

  @callback audience() :: audience()

  @doc "The live view embedded in the tab."
  @callback live_view() :: module()

  @doc """
  The live context of the live view: the page's context (`current_user`,
  `locale`, `is_admin?`, `governable_orgs`), extended with what the view needs.
  """
  @callback live_context(live_context()) :: live_context()

  defmacro __using__(_opts) do
    quote do
      @behaviour Systems.Admin.Panel

      @impl true
      def live_context(context), do: context

      defoverridable live_context: 1
    end
  end

  @doc "Whether `viewer` sees `panel`."
  @spec shown_to?(module(), viewer()) :: boolean()
  def shown_to?(_panel, :admin), do: true
  def shown_to?(panel, :org_admin), do: panel.audience() == :org_admin
end
