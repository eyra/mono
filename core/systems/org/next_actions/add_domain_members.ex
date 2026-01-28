defmodule Systems.Org.NextActions.AddDomainMembers do
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Content
  alias Systems.Org

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"org_id" => org_id, "org_name" => org_name, "domains" => domains}) do
    %{
      title:
        dgettext("eyra-org", "domain.match.next_action.title",
          org_name: org_name,
          domains: domains
        ),
      description: dgettext("eyra-org", "domain.match.next_action.description"),
      cta_label: dgettext("eyra-org", "domain.match.next_action.button"),
      cta_action: %{type: :redirect, to: ~p"/org/node/#{org_id}"}
    }
  end

  # Fallback for legacy NextActions without domains - fetch from database
  def to_view_model(count, %{"org_id" => org_id, "org_name" => org_name}) do
    to_view_model(count, %{"org_id" => org_id, "org_name" => org_name, "domains" => ""})
  end

  # Fallback for legacy NextActions without org_name - fetch org from database
  def to_view_model(count, %{"org_id" => org_id}) do
    org = Org.Public.get_node!(org_id, Org.NodeModel.preload_graph(:full))
    org_name = Content.TextBundleModel.text(org.short_name_bundle, :en)
    domains = format_domains(org.domains)
    to_view_model(count, %{"org_id" => org_id, "org_name" => org_name, "domains" => domains})
  end

  defp format_domains(nil), do: ""
  defp format_domains([]), do: ""
  defp format_domains(domains), do: Enum.join(domains, ", ")
end
