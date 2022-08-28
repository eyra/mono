defmodule Core.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Core.Accounts.{User, Profile, Features}

  alias Core.{
    Authorization,
    DataDonation,
    WebPush,
    Repo
  }

  alias Frameworks.{
    GreenLight
  }

  alias Systems.{
    Notification,
    Campaign,
    Promotion,
    Assignment,
    Crew,
    Support,
    Survey,
    Lab,
    DataDonation,
    Pool,
    Budget,
    Bookkeeping,
    Content,
    Org
  }

  def valid_user_password, do: Faker.Util.format("%5d%5a%5A#")

  def build(:member) do
    %User{
      email: Faker.Internet.email(),
      hashed_password: Bcrypt.hash_pwd_salt(valid_user_password()),
      displayname: Faker.Person.first_name(),
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      profile: %Profile{
        fullname: Faker.Person.name(),
        photo_url: Faker.Avatar.image_url()
      },
      features: %Features{
        gender: :man
      }
    }
  end

  def build(:researcher) do
    :member
    |> build(%{researcher: true})
    |> struct!(%{
      profile: %Profile{
        fullname: Faker.Person.name(),
        photo_url: Faker.Avatar.image_url()
      }
    })
  end

  def build(:coordinator) do
    :member
    |> build(%{
      researcher: true,
      coordinator: true
    })
  end

  def build(:admin) do
    :member
    |> build(%{
      email: "admin1@example.org"
    })
  end

  def build(:student) do
    :member
    |> build(%{student: true})
    |> struct!(%{
      profile: %Profile{
        fullname: Faker.Person.name(),
        photo_url: Faker.Avatar.image_url()
      }
    })
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

  def build(:web_push_subscription) do
    %WebPush.PushSubscription{
      user: build(:member),
      endpoint: Faker.Internet.url(),
      expiration_time: 0,
      auth: Faker.String.base64(22),
      p256dh: Faker.String.base64(87)
    }
  end

  def build(:campaign) do
    build(:campaign, %{})
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

  def build(:author) do
    %Campaign.AuthorModel{
      fullname: Faker.Person.name(),
      displayname: Faker.Person.first_name()
    }
  end

  def build(:survey_tool) do
    build(:survey_tool, %{})
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
      identifier: ["account", Faker.Lorem.word()],
      balance_debit: 0,
      balance_credit: 0
    })
  end

  def build(:fund) do
    build(:book_account, %{
      identifier: ["fund", Faker.Lorem.word()],
      balance_debit: 0,
      balance_credit: 0
    })
  end

  def build(:reserve) do
    build(:book_account, %{
      identifier: ["reserve", Faker.Lorem.word()],
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
    build(:currency, %{name: Faker.Lorem.word()})
  end

  def build(:text_bundle) do
    build(:text_bundle, %{})
  end

  def build(:role_assignment) do
    %Authorization.RoleAssignment{}
  end

  def build(:promotion) do
    build(:promotion, %{})
  end

  def build(:pool) do
    build(:pool, %{name: "test_pool"})
  end

  def build(:criteria) do
    %Pool.CriteriaModel{}
  end

  def build(:submission) do
    build(:submission, %{})
  end

  def build(:experiment) do
    build(:experiment, %{})
  end

  def build(:assignment) do
    build(:assignment, %{})
  end

  def build(:auth_node, %{} = attributes) do
    %Authorization.Node{}
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
    {from, attributes} = Map.pop(attributes, :from, build(:org))
    {to, attributes} = Map.pop(attributes, :to, build(:org))

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

  def build(:author, %{} = attributes) do
    {researcher, attributes} = Map.pop(attributes, :researcher)
    {campaign, _attributes} = Map.pop(attributes, :campaign)

    build(:author)
    |> struct!(%{
      user: researcher,
      campaign: campaign
    })
  end

  def build(:campaign, %{} = attributes) do
    {campaign_auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    {authors, attributes} = Map.pop(attributes, :authors, many_relationship(:authors, attributes))

    {submissions, attributes} =
      Map.pop(attributes, :submissions, many_relationship(:submissions, attributes))

    {promotion, attributes} =
      case Map.pop(attributes, :promotion, nil) do
        {nil, attributes} ->
          {
            build(:promotion, %{auth_node: build(:auth_node, %{parent: campaign_auth_node})}),
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
              director: :campaign,
              auth_node:
                build(
                  :auth_node,
                  %{parent: campaign_auth_node}
                )
            }),
            attributes
          }

        {experiment, attributes} ->
          {experiment, attributes}
      end

    %Campaign.Model{
      auth_node: campaign_auth_node,
      authors: authors,
      promotion: promotion,
      promotable_assignment: assignment,
      submissions: submissions
    }
    |> struct!(attributes)
  end

  def build(:assignment, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {budget, attributes} = Map.pop(attributes, :budget, build(:budget))

    crew_auth_node = build(:auth_node, %{parent: auth_node})
    {crew, attributes} = Map.pop(attributes, :crew, build(:crew, %{auth_node: crew_auth_node}))

    experiment_auth_node = build(:auth_node, %{parent: auth_node})

    {experiment, attributes} =
      case Map.pop(attributes, :experiment, nil) do
        {nil, attributes} -> {build(:experiment, %{auth_node: experiment_auth_node}), attributes}
        {experiment, attributes} -> {experiment, attributes}
      end

    %Assignment.Model{
      auth_node: auth_node,
      budget: budget,
      assignable_experiment: experiment,
      crew: crew,
      excluded: []
    }
    |> struct!(attributes)
  end

  def build(:experiment, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    {lab_tool, attributes} =
      if Map.has_key?(attributes, :lab_tool) do
        Map.pop(attributes, :lab_tool)
      else
        {nil, attributes}
      end

    {survey_tool, attributes} =
      if lab_tool == nil do
        tool_auth_node = build(:auth_node, %{parent: auth_node})

        case Map.pop(attributes, :survey_tool, nil) do
          {nil, attributes} -> {build(:survey_tool, %{auth_node: tool_auth_node}), attributes}
          {survey_tool, attributes} -> {survey_tool, attributes}
        end
      else
        {nil, attributes}
      end

    %Assignment.ExperimentModel{
      auth_node: auth_node,
      survey_tool: survey_tool,
      lab_tool: lab_tool
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
    {member, attributes} = Map.pop(attributes, :member)
    {crew, _attributes} = Map.pop(attributes, :crew)

    %Crew.TaskModel{
      member: member,
      crew: crew
    }
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

  def build(:submission, %{} = attributes) do
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
    %Pool.Model{}
    |> struct!(attributes)
  end

  def build(:data_donation_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %DataDonation.ToolModel{
      auth_node: auth_node
    }
    |> struct!(attributes)
  end

  def build(:survey_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    %Survey.ToolModel{
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
end
