defmodule Core.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Core.Authentication
  alias Core.Authorization
  alias Core.Repo
  alias Core.WebPush
  alias Faker.Random.Elixir
  alias Frameworks.GreenLight
  alias Systems.Account
  alias Systems.Account.User
  alias Systems.Advert
  alias Systems.Affiliate
  alias Systems.Alliance
  alias Systems.Annotation
  alias Systems.Assignment
  alias Systems.Bookkeeping
  alias Systems.Budget
  alias Systems.Consent
  alias Systems.Content
  alias Systems.Crew
  alias Systems.Document
  alias Systems.Feldspar
  alias Systems.Graphite
  alias Systems.Lab
  alias Systems.Manual
  alias Systems.Monitor
  alias Systems.Notification
  alias Systems.Ontology
  alias Systems.Org
  alias Systems.Paper
  alias Systems.Pool
  alias Systems.Project
  alias Systems.Promotion
  alias Systems.Support
  alias Systems.Version
  alias Systems.Workflow
  alias Systems.Zircon

  def valid_user_password, do: Faker.Util.format("%5d%5a%5A#")

  def build(:member) do
    %User{
      email: Faker.Internet.email(),
      hashed_password: Bcrypt.hash_pwd_salt(valid_user_password()),
      displayname: Faker.Person.first_name(),
      confirmed_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
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
    build(:external_user, %{
      organisation: Faker.Company.name(),
      external_id: Faker.UUID.v4()
    })
  end

  def build(:admin) do
    build(:member, %{email: "admin1@example.org"})
  end

  def build(:authentication_entity) do
    build(:authentication_entity, %{
      identifier: "Systems.Account.User:#{Elixir.random_between(1, 1_000_000)}"
    })
  end

  def build(:actor) do
    build(:actor, %{
      type: :system,
      name: "System Actor"
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

  def build(:manual_tool) do
    build(:manual_tool, %{})
  end

  def build(:manual) do
    build(:manual, %{})
  end

  def build(:manual_chapter) do
    build(:chapter, %{})
  end

  def build(:manual_page) do
    build(:page, %{})
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
      identifier: ["wallet", Faker.Lorem.word(), Elixir.random_between(1, 4)],
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
      github_commit_url: "https://github.com/eyra/mono/commit/5405deccef0aa1a594cc09da99185860bc3e0cd2"
    })
  end

  def build(:graphite_tool) do
    build(:graphite_tool, %{})
  end

  def build(:graphite_leaderboard) do
    build(:graphite_leaderboard, %{})
  end

  def build(:workflow) do
    build(:workflow, %{})
  end

  def build(:workflow_item) do
    build(:workflow_item, %{})
  end

  def build(:assignment) do
    build(:assignment, %{})
  end

  def build(:assignment_instance) do
    build(:assignment_instance, %{})
  end

  def build(:affiliate) do
    build(:affiliate, %{
      callback_url: Faker.Internet.url(),
      redirect_url: Faker.Internet.url()
    })
  end

  def build(:affiliate_user) do
    build(:affiliate_user, %{
      identifier: Faker.UUID.v4()
    })
  end

  def build(:affiliate_user_info) do
    build(:affiliate_user_info, %{
      info: Jason.encode!(%{"aap" => "noot", "mies" => "wim", "zus" => "jet"})
    })
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

  def build(:content_file) do
    %Content.FileModel{
      ref: "http://example.com/test_#{System.unique_integer([:positive])}.ris",
      name: "test_#{System.unique_integer([:positive])}.ris"
    }
  end

  def build(:content_page) do
    build(:content_page, %{
      body: "Test page content"
    })
  end

  def build(:zircon_screening_tool) do
    build(:zircon_screening_tool, %{})
  end

  def build(:version) do
    build(:version, %{
      number: 1
    })
  end

  # Paper
  def build(:paper_ris_import_session) do
    build(:paper_ris_import_session, %{})
  end

  def build(:paper_set) do
    build(:paper_set, %{})
  end

  def build(:paper_set_assoc) do
    build(:paper_set_assoc, %{})
  end

  def build(:paper) do
    build(:paper, %{
      version: build(:version),
      title: Faker.Lorem.sentence(),
      year: "#{Enum.random(2020..2024)}",
      authors: [Faker.Person.name()],
      abstract: Faker.Lorem.paragraph(),
      keywords: [Faker.Lorem.word()],
      doi: "10.1234/test.#{System.unique_integer([:positive])}.001"
    })
  end

  def build(:paper_reference_file) do
    build(:paper_reference_file, %{
      status: :uploaded,
      file: build(:content_file)
    })
  end

  # Ontology build/1

  def build(:ontology_concept) do
    build(:ontology_concept, %{
      phrase: 3..5 |> Faker.Lorem.words() |> Enum.join(" "),
      entity: build(:authentication_entity)
    })
  end

  def build(:ontology_predicate) do
    build(:ontology_predicate, %{
      subject: build(:ontology_concept),
      predicate: build(:ontology_concept),
      object: build(:ontology_concept),
      entity: build(:authentication_entity)
    })
  end

  def build(:ontology_ref) do
    build(:ontology_ref, %{
      concept: build(:ontology_concept)
    })
  end

  # Annotation build/1

  def build(:annotation) do
    build(:annotation, %{
      type: build(:ontology_concept),
      statement: Faker.Lorem.word(),
      entity: build(:authentication_entity),
      references: [build(:annotation_ref)]
    })
  end

  def build(:annotation_ref) do
    build(:annotation_ref, %{
      ontology_ref: build(:ontology_ref)
    })
  end

  # build/2
  def build(:role_assignment, %{} = attributes) do
    struct!(%Authorization.RoleAssignment{}, attributes)
  end

  def build(:owner, %{user: user}) do
    build(:role_assignment, %{role: :owner, principal_id: GreenLight.Principal.id(user)})
  end

  def build(:participant, %{user: user}) do
    build(:role_assignment, %{role: :participant, principal_id: GreenLight.Principal.id(user)})
  end

  def build(:auth_node, %{} = attributes) do
    struct!(%Authorization.Node{}, attributes)
  end

  def build(:monitor_event, %{} = attributes) do
    {identifier, attributes} = Map.pop(attributes, :identifier, ["monitor", "event"])
    {value, attributes} = Map.pop(attributes, :value, 1)

    struct!(%Monitor.EventModel{identifier: identifier, value: value}, attributes)
  end

  def build(:org_node, %{} = attributes) do
    {short_name_bundle, attributes} = Map.pop(attributes, :short_name_bundle, build(:text_bundle))
    {full_name_bundle, attributes} = Map.pop(attributes, :full_name_bundle, build(:text_bundle))

    struct!(%Org.NodeModel{short_name_bundle: short_name_bundle, full_name_bundle: full_name_bundle}, attributes)
  end

  def build(:org_link, %{} = attributes) do
    {from, attributes} = Map.pop(attributes, :from, build(:org_node))
    {to, attributes} = Map.pop(attributes, :to, build(:org_node))

    struct!(%Org.LinkModel{from: from, to: to}, attributes)
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

    struct!(%Notification.Box{}, attributes |> Map.delete(:user) |> Map.put(:auth_node, auth_node))
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

    struct!(
      %Advert.Model{auth_node: advert_auth_node, promotion: promotion, assignment: assignment, submission: submission},
      attributes
    )
  end

  def build(:project, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {node, attributes} = Map.pop(attributes, :node, build(:project_node))

    struct!(%Project.Model{auth_node: auth_node, root: node}, attributes)
  end

  def build(:project_node, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {items, attributes} = Map.pop(attributes, :items, [])
    {children, attributes} = Map.pop(attributes, :children, [])

    struct!(%Project.NodeModel{auth_node: auth_node, items: items, children: children}, attributes)
  end

  def build(:project_item, %{} = attributes) do
    {assignment, attributes} = get_optional(:assignment, attributes)

    struct!(%Project.ItemModel{assignment: assignment}, attributes)
  end

  def build(:tool_ref, %{} = attributes) do
    {alliance_tool, attributes} = get_optional(:alliance_tool, attributes)
    {feldspar_tool, attributes} = get_optional(:feldspar_tool, attributes)
    {document_tool, attributes} = get_optional(:document_tool, attributes)
    {lab_tool, attributes} = get_optional(:lab_tool, attributes)
    {graphite_tool, attributes} = get_optional(:graphite_tool, attributes)

    struct!(
      %Workflow.ToolRefModel{
        alliance_tool: alliance_tool,
        document_tool: document_tool,
        lab_tool: lab_tool,
        feldspar_tool: feldspar_tool,
        graphite_tool: graphite_tool
      },
      attributes
    )
  end

  def build(:consent_agreement, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Consent.AgreementModel{auth_node: auth_node}, attributes)
  end

  def build(:consent_revision, %{} = attributes) do
    {agreement, attributes} = Map.pop(attributes, :agreement, build(:consent_agreement))

    struct!(%Consent.RevisionModel{agreement: agreement}, attributes)
  end

  def build(:consent_signature, %{} = attributes) do
    {user, attributes} = Map.pop(attributes, :user, build(:member))
    {revision, attributes} = Map.pop(attributes, :revision, build(:consent_revision))

    struct!(%Consent.SignatureModel{user: user, revision: revision}, attributes)
  end

  def build(:assignment, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {budget, attributes} = Map.pop(attributes, :budget, build(:budget))

    crew_auth_node = build(:auth_node, %{parent: auth_node})
    {crew, attributes} = Map.pop(attributes, :crew, build(:crew, %{auth_node: crew_auth_node}))
    {info, attributes} = Map.pop(attributes, :assignment_info, build(:assignment_info))
    {workflow, attributes} = Map.pop(attributes, :workflow, build(:workflow))
    {affiliate, attributes} = Map.pop(attributes, :affiliate, nil)

    struct!(
      %Assignment.Model{
        auth_node: auth_node,
        budget: budget,
        info: info,
        affiliate: affiliate,
        workflow: workflow,
        crew: crew,
        excluded: []
      },
      attributes
    )
  end

  def build(:assignment_instance, %{} = attributes) do
    struct!(%Assignment.InstanceModel{}, attributes)
  end

  def build(:affiliate, %{} = attributes) do
    struct!(%Affiliate.Model{}, attributes)
  end

  def build(:affiliate_user, %{} = attributes) do
    {user, attributes} = Map.pop(attributes, :user, build(:member))
    {affiliate, attributes} = Map.pop(attributes, :affiliate, build(:affiliate))

    struct!(%Affiliate.User{user: user, affiliate: affiliate}, attributes)
  end

  def build(:affiliate_user_info, %{} = attributes) do
    {user, attributes} = Map.pop(attributes, :user, build(:affiliate_user))

    struct!(%Affiliate.UserInfoModel{user: user}, attributes)
  end

  def build(:assignment_info, %{} = attributes) do
    struct!(%Assignment.InfoModel{}, attributes)
  end

  def build(:assignment_page_ref, %{} = attributes) do
    {assignment, attributes} = Map.pop(attributes, :assignment, build(:assignment))
    {page, attributes} = Map.pop(attributes, :page, build(:content_page))

    struct!(%Assignment.PageRefModel{assignment: assignment, page: page}, attributes)
  end

  def build(:workflow, %{} = attributes) do
    struct!(%Workflow.Model{}, attributes)
  end

  def build(:workflow_item, %{} = attributes) do
    {workflow, attributes} = Map.pop(attributes, :workflow, build(:workflow))
    {tool_ref, attributes} = Map.pop(attributes, :tool_ref, build(:tool_ref))

    struct!(%Workflow.ItemModel{workflow: workflow, tool_ref: tool_ref}, attributes)
  end

  def build(:crew, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Crew.Model{auth_node: auth_node}, attributes)
  end

  def build(:crew_member, %{} = attributes) do
    {user, attributes} = Map.pop(attributes, :user)
    {crew, attributes} = Map.pop(attributes, :crew)

    struct!(%Crew.MemberModel{user: user, crew: crew}, attributes)
  end

  def build(:crew_task, %{} = attributes) do
    {crew, _attributes} = Map.pop(attributes, :crew)

    struct!(%Crew.TaskModel{crew: crew}, attributes)
  end

  def build(:external_user, %{} = attributes) do
    {user, attributes} = Map.pop(attributes, :user, build(:member))

    struct!(%ExternalSignIn.User{user: user}, attributes)
  end

  def build(:member, %{} = attributes) do
    {password, attributes} = Map.pop(attributes, :password)

    :member
    |> build()
    |> struct!(
      if password do
        Map.put(attributes, :hashed_password, Bcrypt.hash_pwd_salt(password))
      else
        attributes
      end
    )
  end

  def build(:authentication_entity, %{} = attributes) do
    struct!(%Authentication.Entity{}, attributes)
  end

  def build(:actor, %{} = attributes) do
    struct!(%Authentication.Actor{}, attributes)
  end

  def build(:pool_submission, %{} = attributes) do
    {criteria, attributes} = Map.pop(attributes, :criteria, build(:criteria))
    {pool, attributes} = Map.pop(attributes, :pool, build(:pool))

    struct!(%Pool.SubmissionModel{status: :idle, criteria: criteria, pool: pool}, attributes)
  end

  def build(:promotion, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Promotion.Model{auth_node: auth_node, title: Faker.Lorem.sentence()}, attributes)
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

    struct!(%Pool.Model{auth_node: auth_node, currency: currency, org: org_node}, attributes)
  end

  def build(:graphite_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Graphite.ToolModel{auth_node: auth_node}, attributes)
  end

  def build(:graphite_submission, %{} = attributes) do
    {tool, attributes} = Map.pop(attributes, :tool, build(:graphite_tool))
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Graphite.SubmissionModel{tool: tool, auth_node: auth_node}, attributes)
  end

  def build(:graphite_leaderboard, %{} = attributes) do
    {tool, attributes} = Map.pop(attributes, :tool, build(:graphite_tool))
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Graphite.LeaderboardModel{tool: tool, auth_node: auth_node}, attributes)
  end

  def build(:feldspar_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Feldspar.ToolModel{auth_node: auth_node}, attributes)
  end

  def build(:document_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Document.ToolModel{auth_node: auth_node}, attributes)
  end

  def build(:alliance_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Alliance.ToolModel{auth_node: auth_node}, attributes)
  end

  def build(:lab_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Lab.ToolModel{auth_node: auth_node}, attributes)
  end

  def build(:manual_tool, %{} = attributes) do
    {manual, attributes} = Map.pop(attributes, :manual, build(:manual))
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Manual.ToolModel{manual: manual, auth_node: auth_node}, attributes)
  end

  def build(:time_slot, %{} = attributes) do
    {lab_tool, attributes} = Map.pop(attributes, :lab_tool, build(:lab_tool))
    {reservations, attributes} = Map.pop(attributes, :reservations, [])

    struct!(%Lab.TimeSlotModel{tool: lab_tool, reservations: reservations}, attributes)
  end

  def build(:budget, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {currency, attributes} = Map.pop(attributes, :currency, build(:currency))
    {fund, attributes} = Map.pop(attributes, :fund, build(:fund))
    {reserve, attributes} = Map.pop(attributes, :reserve, build(:reserve))

    struct!(%Budget.Model{currency: currency, fund: fund, reserve: reserve, auth_node: auth_node}, attributes)
  end

  def build(:bank_account, %{} = attributes) do
    {currency, attributes} = Map.pop(attributes, :currency, build(:currency))
    {account, attributes} = Map.pop(attributes, :account, build(:book_account))

    struct!(%Budget.BankAccountModel{currency: currency, account: account}, attributes)
  end

  def build(:book_account, %{} = attributes) do
    struct!(%Bookkeeping.AccountModel{}, attributes)
  end

  def build(:book_entry, %{} = attributes) do
    struct!(%Bookkeeping.EntryModel{}, attributes)
  end

  def build(:book_line, %{} = attributes) do
    {account, attributes} = Map.pop(attributes, :account, build(:book_account))
    {entry, attributes} = Map.pop(attributes, :entry, build(:book_entry))

    struct!(%Bookkeeping.LineModel{account: account, entry: entry}, attributes)
  end

  def build(:currency, %{} = attributes) do
    {label_bundle, attributes} = Map.pop(attributes, :label_bundle, build(:text_bundle))

    struct!(%Budget.CurrencyModel{label_bundle: label_bundle}, attributes)
  end

  def build(:reward, %{} = attributes) do
    {budget, attributes} = Map.pop(attributes, :budget, build(:budget))
    {user, attributes} = Map.pop(attributes, :user, build(:member))
    {deposit, attributes} = Map.pop(attributes, :deposit, nil)
    {payment, attributes} = Map.pop(attributes, :payment, nil)

    struct!(%Budget.RewardModel{budget: budget, user: user, deposit: deposit, payment: payment}, attributes)
  end

  def build(:text_bundle, %{} = attributes) do
    {items, attributes} = Map.pop(attributes, :items, [])

    struct!(%Content.TextBundleModel{items: items}, attributes)
  end

  def build(:text_item, %{} = attributes) do
    {bundle, attributes} = Map.pop(attributes, :bundle, build(:text_bundle))

    struct!(%Content.TextItemModel{bundle: bundle}, attributes)
  end

  def build(:zircon_screening_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Zircon.Screening.ToolModel{auth_node: auth_node}, attributes)
  end

  # Ontology build/2
  def build(:ontology_concept, %{} = attributes) do
    {entity, attributes} = Map.pop(attributes, :entity, build(:authentication_entity))

    struct!(%Ontology.ConceptModel{entity: entity}, attributes)
  end

  def build(:ontology_predicate, %{} = attributes) do
    {entity, attributes} = Map.pop(attributes, :entity, build(:authentication_entity))
    {subject, attributes} = Map.pop(attributes, :subject, build(:ontology_concept))
    {type, attributes} = Map.pop(attributes, :type, build(:ontology_concept))
    {object, attributes} = Map.pop(attributes, :object, build(:ontology_concept))

    struct!(%Ontology.PredicateModel{entity: entity, subject: subject, type: type, object: object}, attributes)
  end

  def build(:ontology_ref, %{} = attributes) do
    {concept, attributes} = Map.pop(attributes, :ontology_concept)
    {predicate, attributes} = Map.pop(attributes, :ontology_predicate)

    # at least one of concept or predicate must be present
    concept =
      if is_nil(concept) && is_nil(predicate),
        do: build(:ontology_concept),
        else: concept

    struct!(%Ontology.RefModel{concept: concept, predicate: predicate}, attributes)
  end

  # Annotation build/2

  def build(:annotation, %{} = attributes) do
    {type, attributes} = Map.pop(attributes, :type, build(:ontology_concept))
    {entity, attributes} = Map.pop(attributes, :entity, build(:authentication_entity))
    {references, attributes} = Map.pop(attributes, :references, [build(:annotation_ref)])

    struct!(%Annotation.Model{type: type, entity: entity, references: references}, attributes)
  end

  def build(:annotation_ref, %{} = attributes) do
    {annotation, attributes} = Map.pop(attributes, :annotation)
    {ontology_ref, attributes} = Map.pop(attributes, :ontology_ref)

    # at least one of annotation or ontology_ref must be present
    ontology_ref =
      if is_nil(ontology_ref) && is_nil(annotation),
        do: build(:ontology_ref),
        else: ontology_ref

    struct!(%Annotation.RefModel{annotation: annotation, ontology_ref: ontology_ref}, attributes)
  end

  def build(:content_file, %{} = attributes) do
    struct!(%Content.FileModel{}, attributes)
  end

  def build(:content_page, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    struct!(%Content.PageModel{auth_node: auth_node}, attributes)
  end

  def build(:version, %{} = attributes) do
    struct!(%Version.Model{}, attributes)
  end

  # Paper

  def build(:paper_ris_import_session, %{} = attributes) do
    {paper_set, attributes} = Map.pop(attributes, :paper_set, build(:paper_set))

    {reference_file, attributes} =
      Map.pop(attributes, :reference_file, build(:paper_reference_file))

    struct!(%Paper.RISImportSessionModel{paper_set: paper_set, reference_file: reference_file}, attributes)
  end

  def build(:paper, %{} = attributes) do
    {version, attributes} = Map.pop(attributes, :version, build(:version))
    {sets, attributes} = Map.pop(attributes, :sets, [])

    struct!(%Paper.Model{version: version, sets: sets}, attributes)
  end

  def build(:paper_set, %{} = attributes) do
    {papers, attributes} = Map.pop(attributes, :papers, [])

    struct!(%Paper.SetModel{papers: papers}, attributes)
  end

  def build(:paper_set_assoc, %{} = attributes) do
    {paper, attributes} = Map.pop(attributes, :paper, build(:paper))
    {set, attributes} = Map.pop(attributes, :set, build(:paper_set))

    struct!(%Paper.SetAssoc{paper: paper, set: set}, attributes)
  end

  def build(:paper_reference_file, %{} = attributes) do
    {file, attributes} = Map.pop(attributes, :file, build(:content_file))

    struct!(%Paper.ReferenceFileModel{file: file}, attributes)
  end

  # Generic

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
    Enum.map(enumerable, &build(factory, attributes_fn.(&1)))
  end

  def many_relationship(name, %{} = attributes) do
    result = Map.get(attributes, name)

    if result === nil do
      []
    else
      result
    end
  end

  defp random_identifier(type) when is_atom(type), do: type |> Atom.to_string() |> random_identifier()

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
