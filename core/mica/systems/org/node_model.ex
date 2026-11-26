defmodule Systems.Org.NodeModel do
  use Ecto.Schema
  use Gettext, backend: MicaWeb.Gettext
  import Ecto.Changeset
  import Frameworks.Utility.EctoHelper, only: [apply_virtual_change: 4]

  alias Systems.Account.User

  use Systems.{
    Org.Internals
  }

  alias Systems.{
    Content
  }

  schema "org_nodes" do
    field(:identifier, {:array, :string})
    field(:identifier_string, :string, virtual: true)
    field(:domains, {:array, :string})
    field(:domains_string, :string, virtual: true)
    field(:archived_at, :utc_datetime)
    field(:research_institute_at, :utc_datetime)

    belongs_to(:research_institute_by, User)
    belongs_to(:auth_node, Mica.Authorization.Node)
    belongs_to(:short_name_bundle, Content.TextBundleModel, on_replace: :update)
    belongs_to(:full_name_bundle, Content.TextBundleModel, on_replace: :update)

    many_to_many(:users, User,
      join_through: Org.UserAssociation,
      join_keys: [org_id: :id, user_id: :id]
    )

    many_to_many(
      :links,
      Node,
      join_through: Link,
      join_keys: [from_id: :id, to_id: :id]
    )

    many_to_many(
      :reverse_links,
      Node,
      join_through: Link,
      join_keys: [to_id: :id, from_id: :id]
    )

    timestamps()
  end

  @fields ~w(identifier identifier_string domains_string)a
  @required_fields ~w(identifier)a

  def preload_graph(:full) do
    [
      :users,
      :links,
      :reverse_links,
      :auth_node,
      research_institute_by: [:profile],
      short_name_bundle: Content.TextBundleModel.preload_graph(:full),
      full_name_bundle: Content.TextBundleModel.preload_graph(:full)
    ]
  end

  def create(attrs, short_name_bundle, full_name_bundle, auth_node \\ nil) do
    %Node{}
    |> Ecto.Changeset.cast(attrs, [:identifier])
    |> Ecto.Changeset.unique_constraint(:identifier)
    |> Ecto.Changeset.put_assoc(:short_name_bundle, short_name_bundle)
    |> Ecto.Changeset.put_assoc(:full_name_bundle, full_name_bundle)
    |> maybe_put_auth_node(auth_node)
  end

  defp maybe_put_auth_node(changeset, nil), do: changeset

  defp maybe_put_auth_node(changeset, auth_node) do
    Ecto.Changeset.put_assoc(changeset, :auth_node, auth_node)
  end

  def changeset(node, attrs) do
    node
    |> prepare_virtual()
    |> cast(attrs, @fields)
    |> apply_text_bundle_changes(attrs, :full_name_bundle)
    |> apply_text_bundle_changes(attrs, :short_name_bundle)
    |> apply_virtual_changes()
    |> validate_required(@required_fields)
    |> validate_length(:identifier, min: 1)
    |> validate_change(:domains, &validate_domains/2)
    |> unique_constraint(:identifier)
  end

  # Labels of letters, digits and inner hyphens, ending in a label that starts
  # with a letter: `uni.nl`, `mail.uni-a.nl`, `xn--80ak6aa92e.com`.
  @domain_format ~r/\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i

  # The error goes on `domains_string`, the field the form shows.
  defp validate_domains(:domains, domains) do
    if Enum.all?(domains, &domain?/1) do
      []
    else
      [domains_string: dgettext("eyra-org", "domains.invalid.error")]
    end
  end

  defp domain?(domain), do: String.length(domain) <= 253 and domain =~ @domain_format

  @doc """
  Changes only the names. Identifier and domains are left out: domains decide
  who can join as a member, so only system admins change them (`changeset/2`).
  """
  def names_changeset(node, attrs) do
    node
    |> prepare_virtual()
    |> change()
    |> apply_text_bundle_changes(attrs, :full_name_bundle)
    |> apply_text_bundle_changes(attrs, :short_name_bundle)
  end

  defp prepare_virtual(%{identifier: identifier, domains: domains} = node) do
    %{
      node
      | identifier_string: to_string(identifier, "_"),
        domains_string: to_string(domains, " ")
    }
  end

  defp apply_text_bundle_changes(changeset, attrs, field) do
    Content.TextBundleModel.apply_text_bundle_changes(changeset, attrs, field)
  end

  defp to_string(nil, _delimiter), do: ""
  defp to_string(field, delimiter), do: field |> Enum.join(delimiter)

  defp apply_virtual_changes(changeset) do
    changeset
    |> apply_virtual_change(:identifier, :identifier_string, ["_"])
    |> apply_virtual_change(:domains, :domains_string, [" ", ","])
  end

  def archived?(%{archived_at: nil}), do: false
  def archived?(%{archived_at: _}), do: true

  def archive_changeset(node) do
    node
    |> change(%{archived_at: DateTime.utc_now() |> DateTime.truncate(:second)})
  end

  def restore_changeset(node) do
    node
    |> change(%{archived_at: nil})
  end

  def research_institute?(%{research_institute_at: nil}), do: false
  def research_institute?(%{research_institute_at: _}), do: true

  def research_institute_changeset(node, true, %User{id: by_id}) do
    change(node, %{
      research_institute_at: DateTime.utc_now() |> DateTime.truncate(:second),
      research_institute_by_id: by_id
    })
  end

  def research_institute_changeset(node, false, _by) do
    change(node, %{research_institute_at: nil, research_institute_by_id: nil})
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(org_node), do: org_node.auth_node_id
  end
end
