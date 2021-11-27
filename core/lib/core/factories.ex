defmodule Core.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Core.Accounts.{User, Profile, Features}

  alias Core.{
    Content,
    Pools,
    Authorization,
    DataDonation,
    WebPush,
    Helpdesk
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
    Survey,
    Lab
  }

  alias Core.Repo

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
    %Helpdesk.Ticket{
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

  # def build(:client_script) do
  #   %DataDonation.Tool{
  #     title: Faker.Lorem.sentence(),
  #     script: "print 'hello'"
  #   }

  # end

  def build(:role_assignment) do
    %Authorization.RoleAssignment{}
  end

  def build(:promotion) do
    build(:promotion, %{})
  end

  def build(:pool) do
    %Pools.Pool{name: :vu_students}
  end

  def build(:criteria) do
    %Pools.Criteria{}
  end

  def build(:submission) do
    build(:submission, %{})
  end

  def build(:assignment) do
    build(:assignment, %{})
  end

  def build(:content_node) do
    %Content.Node{ready: true}
  end

  def build(:content_node, %{} = attributes) do
    %Content.Node{}
    |> struct!(attributes)
  end

  def build(:auth_node, %{} = attributes) do
    %Authorization.Node{}
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

    {promotion, attributes} =
      Map.pop(
        attributes,
        :promotion,
        build(:promotion, %{auth_node: build(:auth_node, %{parent: campaign_auth_node})})
      )

    {assignment, attributes} =
      Map.pop(
        attributes,
        :assignment,
        build(:assignment, %{
          director: :campaign,
          auth_node: build(:auth_node, %{parent: campaign_auth_node})
        })
      )

    %Campaign.Model{
      auth_node: campaign_auth_node,
      authors: authors,
      promotion: promotion,
      promotable_assignment: assignment
    }
    |> struct!(attributes)
  end

  def build(:assignment, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))

    crew_auth_node = build(:auth_node, %{parent: auth_node})
    {crew, attributes} = Map.pop(attributes, :crew, build(:crew, %{auth_node: crew_auth_node}))

    {datadonation_tool, attributes} =
      if Map.has_key?(attributes, :datadonation_tool) do
        Map.pop(attributes, :datadonation_tool)
      else
        {nil, attributes}
      end

    {survey_tool, attributes} =
      if datadonation_tool == nil do
        tool_auth_node = build(:auth_node, %{parent: auth_node})
        Map.pop(attributes, :survey_tool, build(:survey_tool, %{auth_node: tool_auth_node}))
      else
        {nil, attributes}
      end

    %Assignment.Model{
      auth_node: auth_node,
      assignable_survey_tool: survey_tool,
      assignable_data_donation_tool: datadonation_tool,
      crew: crew
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
    {promotion, attributes} = Map.pop!(attributes, :promotion)
    content_node = build(:content_node, %{parent: promotion.content_node})

    {criteria, attributes} = Map.pop(attributes, :criteria, build(:criteria))
    {pool, attributes} = Map.pop(attributes, :pool, Pools.get_by_name(:vu_students))

    %Pools.Submission{
      promotion_id: promotion.id,
      status: :idle,
      criteria: criteria,
      pool: pool,
      content_node: content_node
    }
    |> struct!(attributes)
  end

  def build(:promotion, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {content_node, attributes} = Map.pop(attributes, :content_node, build(:content_node))

    %Promotion.Model{
      auth_node: auth_node,
      content_node: content_node,
      title: Faker.Lorem.sentence()
    }
    |> struct!(attributes)
  end

  def build(:data_donation_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {content_node, attributes} = Map.pop(attributes, :content_node, build(:content_node))

    %DataDonation.Tool{
      auth_node: auth_node,
      content_node: content_node
    }
    |> struct!(attributes)
  end

  def build(:survey_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {content_node, attributes} = Map.pop(attributes, :content_node, build(:content_node))

    %Survey.ToolModel{
      auth_node: auth_node,
      content_node: content_node
    }
    |> struct!(attributes)
  end

  def build(:lab_tool, %{} = attributes) do
    {auth_node, attributes} = Map.pop(attributes, :auth_node, build(:auth_node))
    {content_node, attributes} = Map.pop(attributes, :content_node, build(:content_node))

    %Lab.ToolModel{
      auth_node: auth_node,
      content_node: content_node
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
