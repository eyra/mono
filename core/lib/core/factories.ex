defmodule Core.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """

  alias Core.Authorization
  alias Core.WebPush
  alias Core.Repo

  alias Frameworks.GreenLight

  alias Systems.Account
  alias Systems.Account.User
  alias Systems.Notification
  alias Systems.Advert
  alias Systems.Promotion
  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Crew
  alias Systems.Support
  alias Systems.Alliance
  alias Systems.Feldspar
  alias Systems.Document
  alias Systems.Lab
  alias Systems.Graphite
  alias Systems.Pool
  alias Systems.Budget
  alias Systems.Bookkeeping
  alias Systems.Content
  alias Systems.Org
  alias Systems.Project
  alias Systems.Consent
  alias Systems.Monitor

  def valid_user_password, do: Faker.Util.format("%5d%5a%5A#")

  def build(:member) do
    %User{
      email: Faker.Internet.email(),
      hashed_password: Bcrypt.hash_pwd_salt(valid_user_password()),
      displayname: Faker.Person.first_name(),
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      profile: %Account.UserProfileModel{
        fullname: Faker.Person.name(),
        photo_url: Faker.Avatar.image_url()
      },
      features: %Account.FeaturesModel{
        gender: :man
      }
    }
  end

  def build(:creator) do
    :member
    |> build(%{creator: true})
    |> struct!(%{
      profile: %Account.UserProfileModel{
        fullname: Faker.Person.name(),
        photo_url: Faker.Avatar.image_url()
      }
    })
  end

  def build(:external_user) do
    %ExternalSignIn.User{
      external_id: Faker.UUID.v4(),
      organisation: Faker.Company.name(),
      user: build(:member)
    }
  end

  def build(:admin) do
    :member
    |> build(%{
      email: "admin1@example.org"
    })
  end

  def build(:role_assignment) do
    %Authorization.RoleAssignment{}
  end

  def build(:auth_node) do
    %Authorization.Node{}
  end

  def build(:org_node) do
    build(:org_node, %{})
  end

  def build(:org_link) do
    build(:org_link, %{})
  end

  def build(:monitor_event) do
    build(:monitor_event, %{})
  end

  def build(:web_push_subscription) do
    %WebPush.PushSubscription{
      user: build(:member),
      endpoint: Faker.Internet.url(),
      expiration_time: 0,
      auth: Faker.String.base64(22),
      p256dh: Faker.String.base64(87)
    }
  end

  def build(:advert) do
    build(:advert, %{})
  end

  def build(:crew) do
    %Crew.Model{}
  end

  def build(:crew_member) do
    %Crew.MemberModel{}
  end

  def build(:crew_task) do
    %Crew.TaskModel{}
  end

  def build(:helpdesk_ticket) do
    %Support.TicketModel{
      title: Faker.Lorem.sentence(),
      description: Faker.Lorem.paragraph(),
      user: build(:member)
    }
  end

  def build(:alliance_tool) do
    build(:alliance_tool, %{})
  end

  def build(:feldspar_tool) do
    build(:feldspar_tool, %{})
  end

  def build(:document_tool) do
    build(:document_tool, %{})
  end

  def build(:lab_tool) do
    build(:lab_tool, %{})
  end

  def build(:time_slot) do
    build(:time_slot, %{})
  end

  def build(:budget) do
    build(:budget, %{name: Faker.Lorem.sentence()})
  end

  def build(:book_account) do
    build(:book_account, %{
      identifier: random_identifier(:account),
      balance_debit: 0,
      balance_credit: 0
    })
  end

  def build(:fund) do
    build(:book_account, %{
      identifier: random_identifier(:fund),
      balance_debit: 0,
      balance_credit: 0
    })
  end

  def build(:reserve) do
    build(:book_account, %{
      identifier: random_identifier(:reserve),
      balance_debit: 0,
      balance_credit: 0
    })
  end

  def build(:book_entry) do
    build(:book_entry, %{})
  end

  def build(:book_line) do
    build(:book_line, %{})
  end

  def build(:wallet) do
    build(:book_account, %{
      identifier: ["wallet", Faker.Lorem.word(), Faker.Random.Elixir.random_between(1, 4)],
      balance_debit: 0,
      balance_credit: 0
    })
  end

  def build(:currency) do
    build(:currency, %{name: Faker.UUID.v4()})
  end

  def build(:text_bundle) do
    build(:text_bundle, %{})
  end

  def build(:promotion) do
    build(:promotion, %{})
  end

  def build(:pool) do
    build(:pool, %{name: "test_pool", director: :citizen})
  end

  def build(:criteria) do
    %Pool.CriteriaModel{}
  end

  def build(:pool_submission) do
    build(:pool_submission, %{})
  end

  def build(:graphite_submission) do
    build(:graphite_submission, %{
      description: "description",
      github_commit_url:
        "https://github.com/eyra/mono/commit/5405deccef0aa1a594cc09da99185860bc3e0cd2"
    })
  end

  def build(:graphite_tool) do
    build(:graphite_tool, %{})
  end

  def build(:graphite_leaderboard) do
    build(:graphite_leaderboard, %{})
  end

  def build(:workflow) do
    build(:workflow, %{type: :many_optional})
  end

  def build(:workflow_item) do
    build(:workflow_item, %{})
  end

  def build(:assignment) do
    build(:assignment, %{})
  end

  def build(:assignment_info) do
    build(:assignment_info, %{})
  end

  def build(:project) do
    build(:project, %{name: Faker.Lorem.word()})
  end

  def build(:project_node) do
    build(:project_node, %{name: Faker.Lorem.word(), project_path: []})
  end

  def build(:project_item) do
    build(:project_item, %{name: Faker.Lorem.word(), project_path: []})
  end

  def build(:tool_ref) do
    build(:tool_ref, %{})
  end

  def build(:consent_agreement) do
    build(:consent_agreement, %{})
  end

  def build(:consent_revision) do
    build(:consent_revision, %{})
  end

  def build(:consent_signature) do
    build(:consent_signature, %{})
  end

  def build(:role_assignment, %{} = attributes) do
    %Authorization.RoleAssignment{}
    |> struct!(attributes)
  end

  def build(:owner, %{user: user}) do
    build(:role_assignment, %{role: :owner, principal_id: GreenLight.Principal.id(user)})
  end

  def build(:participant, %{user: user}) do
    build(:role_assignment, %{role: :participant, principal_id: GreenLight.Principal.id(user)})
  end

  def build(:auth_node, %{} = attributes) do
    %Authorization.Node{}
    |> struct!(attributes)
  end

  def build(:monitor_event, %{} = attributes) do
    {identifier, attributes} = Map.pop(attributes, :identifier, ["monitor", "event"])
    {value, attributes} = Map.pop(attributes, :value, 1)

    %Monitor.EventModel{
      identifier: identifier,
      value: value
    }
    |> struct!(attributes)
  end

  def build(:org_node, %{} = attributes) do
    {short_name_bundle, attributes} = Map.pop(attributes, :short_name_bundle, build(:text_bundle))
    {full_name_bundle, attributes} = Map.pop(attributes, :full_name_bundle, build(:text_bundle))

    %Org.NodeModel{
      short_name_bundle: short_name_bundle,
      full_name_bundle: full_name_bundle
    }
    |> struct!(attributes)
  end

  def build(:org_link, %{} = attributes) do
    {from, attributes} = Map.pop(attributes, :from, build(:org_node))
    {to, attributes} = Map.pop(attributes, :to, build(:org_node))

    %Org.LinkModel{
      from: from,
      to: to
    }
    |> struct!(attributes)
  end

  def build(:notification_box, %{user: user} = attributes) do
    auth_node =
      build(:auth_node, %{
        role_assignments: [
          %{
            role: :owner,
            principal_id: GreenLight.Principal.id(user)
          }
        ]
      })

    %Notification.Box{}
    |> struct!(
      Map.delete(attributes, :user)
      |> Map.put(:auth_node, auth_node)
    )
  end

  def build(:advert, %{} = attributes) do
    {advert_auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {submission, attributes} = Map.pop(attributes, :submission, build(:pool_submission))

    {promotion, attributes} =
      case Map.pop(attributes, :promotion, nil) do
        {nil, attributes} ->
          {
            build(:promotion, %{auth_node: build(:auth_node, %{parent: advert_auth_node})}),
            attributes
          }

        {promotion, attributes} ->
          {promotion, attributes}
      end

    {assignment, attributes} =
      case Map.pop(attributes, :assignment, nil) do
        {nil, attributes} ->
          {
            build(:assignment, %{
              auth_node:
                build(
                  :auth_node,
                  %{parent: advert_auth_node}
                )
            }),
            attributes
          }

        {assignment, attributes} ->
          {assignment, attributes}
      end

    %Advert.Model{
      auth_node: advert_auth_node,
      promotion: promotion,
      assignment: assignment,
      submission: submission
    }
    |> struct!(attributes)
  end

  def build(:project, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {node, attributes} = Map.pop(attributes, :node, build(:project_node))

    %Project.Model{
      auth_node: auth_node,
      root: node
    }
    |> struct!(attributes)
  end

  def build(:project_node, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {items, attributes} = Map.pop(attributes, :items, [])
    {children, attributes} = Map.pop(attributes, :children, [])

    %Project.NodeModel{
      auth_node: auth_node,
      items: items,
      children: children
    }
    |> struct!(attributes)
  end

  def build(:project_item, %{} = attributes) do
    {assignment, attributes} = get_optional(:assignment, attributes)

    %Project.ItemModel{
      assignment: assignment
    }
    |> struct!(attributes)
  end

  def build(:tool_ref, %{} = attributes) do
    {alliance_tool, attributes} = get_optional(:alliance_tool, attributes)
    {feldspar_tool, attributes} = get_optional(:feldspar_tool, attributes)
    {document_tool, attributes} = get_optional(:document_tool, attributes)
    {lab_tool, attributes} = get_optional(:lab_tool, attributes)
    {graphite_tool, attributes} = get_optional(:graphite_tool, attributes)

    %Workflow.ToolRefModel{
      alliance_tool: alliance_tool,
      document_tool: document_tool,
      lab_tool: lab_tool,
      feldspar_tool: feldspar_tool,
      graphite_tool: graphite_tool
    }
    |> struct!(attributes)
  end

  def build(:consent_agreement, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Consent.AgreementModel{
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:consent_revision, %{} = attributes) do
    {agreement, attributes} = Map.pop(attributes, :agreement, build(:consent_agreement))

    %Consent.RevisionModel{
      agreement: agreement
    }
    |> struct!(attributes)
  end

  def build(:consent_signature, %{} = attributes) do
    {user, attributes} = Map.pop(attributes, :user, build(:member))
    {revision, attributes} = Map.pop(attributes, :revision, build(:consent_revision))

    %Consent.SignatureModel{
      user: user,
      revision: revision
    }
    |> struct!(attributes)
  end

  def build(:assignment, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {budget, attributes} = Map.pop(attributes, :budget, build(:budget))

    crew_auth_node = build(:auth_node, %{parent: auth_node})
    {crew, attributes} = Map.pop(attributes, :crew, build(:crew, %{auth_node: crew_auth_node}))
    {info, attributes} = Map.pop(attributes, :assignment_info, build(:assignment_info))
    {workflow, attributes} = Map.pop(attributes, :workflow, build(:workflow))

    %Assignment.Model{
      auth_node: auth_node,
      budget: budget,
      info: info,
      workflow: workflow,
      crew: crew,
      excluded: []
    }
    |> struct!(attributes)
  end

  def build(:assignment_info, %{} = attributes) do
    %Assignment.InfoModel{}
    |> struct!(attributes)
  end

  def build(:workflow, %{} = attributes) do
    %Workflow.Model{}
    |> struct!(attributes)
  end

  def build(:workflow_item, %{} = attributes) do
    {workflow, attributes} = Map.pop(attributes, :workflow, build(:workflow))
    {tool_ref, attributes} = Map.pop(attributes, :tool_ref, build(:tool_ref))

    %Workflow.ItemModel{
      workflow: workflow,
      tool_ref: tool_ref
    }
    |> struct!(attributes)
  end

  def build(:crew, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Crew.Model{
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:crew_member, %{} = attributes) do
    {user, attributes} = Map.pop(attributes, :user)
    {crew, attributes} = Map.pop(attributes, :crew)

    %Crew.MemberModel{
      user: user,
      crew: crew
    }
    |> struct!(attributes)
  end

  def build(:crew_task, %{} = attributes) do
    {crew, _attributes} = Map.pop(attributes, :crew)

    %Crew.TaskModel{
      crew: crew
    }
    |> struct!(attributes)
  end

  def build(:external_user, %{} = attributes) do
    build(:external_user)
    |> struct!(attributes)
  end

  def build(:member, %{} = attributes) do
    {password, attributes} = Map.pop(attributes, :password)

    build(:member)
    |> struct!(
      if password do
        Map.put(attributes, :hashed_password, Bcrypt.hash_pwd_salt(password))
      else
        attributes
      end
    )
  end

  def build(:pool_submission, %{} = attributes) do
    {criteria, attributes} = Map.pop(attributes, :criteria, build(:criteria))
    {pool, attributes} = Map.pop(attributes, :pool, build(:pool))

    %Pool.SubmissionModel{
      status: :idle,
      criteria: criteria,
      pool: pool
    }
    |> struct!(attributes)
  end

  def build(:promotion, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Promotion.Model{
      auth_node: auth_node,
      title: Faker.Lorem.sentence()
    }
    |> struct!(attributes)
  end

  def build(:pool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {currency, attributes} = Map.pop(attributes, :currency, build(:currency))

    {org_node, attributes} =
      Map.pop(
        attributes,
        :org_node,
        build(:org_node, %{type: :university, identifier: random_identifier(:org)})
      )

    %Pool.Model{
      auth_node: auth_node,
      currency: currency,
      org: org_node
    }
    |> struct!(attributes)
  end

  def build(:graphite_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Graphite.ToolModel{
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:graphite_submission, %{} = attributes) do
    {tool, attributes} = Map.pop(attributes, :tool, build(:graphite_tool))
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Graphite.SubmissionModel{
      tool: tool,
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:graphite_leaderboard, %{} = attributes) do
    {tool, attributes} = Map.pop(attributes, :tool, build(:graphite_tool))
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Graphite.LeaderboardModel{
      tool: tool,
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:feldspar_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Feldspar.ToolModel{
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:document_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Document.ToolModel{
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:alliance_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Alliance.ToolModel{
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:lab_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Lab.ToolModel{
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:time_slot, %{} = attributes) do
    {lab_tool, attributes} = Map.pop(attributes, :lab_tool, build(:lab_tool))
    {reservations, attributes} = Map.pop(attributes, :reservations, [])

    %Lab.TimeSlotModel{
      tool: lab_tool,
      reservations: reservations
    }
    |> struct!(attributes)
  end

  def build(:budget, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {currency, attributes} = Map.pop(attributes, :currency, build(:currency))
    {fund, attributes} = Map.pop(attributes, :fund, build(:fund))
    {reserve, attributes} = Map.pop(attributes, :reserve, build(:reserve))

    %Budget.Model{
      currency: currency,
      fund: fund,
      reserve: reserve,
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:bank_account, %{} = attributes) do
    {currency, attributes} = Map.pop(attributes, :currency, build(:currency))
    {account, attributes} = Map.pop(attributes, :account, build(:book_account))

    %Budget.BankAccountModel{
      currency: currency,
      account: account
    }
    |> struct!(attributes)
  end

  def build(:book_account, %{} = attributes) do
    %Bookkeeping.AccountModel{}
    |> struct!(attributes)
  end

  def build(:book_entry, %{} = attributes) do
    %Bookkeeping.EntryModel{}
    |> struct!(attributes)
  end

  def build(:book_line, %{} = attributes) do
    {account, attributes} = Map.pop(attributes, :account, build(:book_account))
    {entry, attributes} = Map.pop(attributes, :entry, build(:book_entry))

    %Bookkeeping.LineModel{
      account: account,
      entry: entry
    }
    |> struct!(attributes)
  end

  def build(:currency, %{} = attributes) do
    {label_bundle, attributes} = Map.pop(attributes, :label_bundle, build(:text_bundle))

    %Budget.CurrencyModel{
      label_bundle: label_bundle
    }
    |> struct!(attributes)
  end

  def build(:reward, %{} = attributes) do
    {budget, attributes} = Map.pop(attributes, :budget, build(:budget))
    {user, attributes} = Map.pop(attributes, :user, build(:member))
    {deposit, attributes} = Map.pop(attributes, :deposit, nil)
    {payment, attributes} = Map.pop(attributes, :payment, nil)

    %Budget.RewardModel{
      budget: budget,
      user: user,
      deposit: deposit,
      payment: payment
    }
    |> struct!(attributes)
  end

  def build(:text_bundle, %{} = attributes) do
    {items, attributes} = Map.pop(attributes, :items, [])

    %Content.TextBundleModel{
      items: items
    }
    |> struct!(attributes)
  end

  def build(:text_item, %{} = attributes) do
    {bundle, attributes} = Map.pop(attributes, :bundle, build(:text_bundle))

    %Content.TextItemModel{
      bundle: bundle
    }
    |> struct!(attributes)
  end

  def build(factory_name, %{} = attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name) do
    insert!(factory_name, %{})
  end

  def insert!(factory_name, %{} = attributes) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  def map_build(enumerable, factory, attributes_fn) do
    enumerable |> Enum.map(&build(factory, attributes_fn.(&1)))
  end

  def many_relationship(name, %{} = attributes) do
    result = Map.get(attributes, name)

    if result === nil do
      []
    else
      result
    end
  end

  defp random_identifier(type) when is_atom(type), do: random_identifier(type |> Atom.to_string())

  defp random_identifier(type) when is_binary(type) do
    [type] ++ Faker.Lorem.words(3..5)
  end

  defp get_optional(key, attributes) do
    if Map.has_key?(attributes, key) do
      Map.pop(attributes, key)
    else
      {nil, attributes}
    end
  end
end
