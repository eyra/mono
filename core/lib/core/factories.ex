defmodule Core.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Core.Accounts.{User, Profile}

  alias Core.{
    Studies,
    Content,
    Promotions,
    Pools,
    Survey,
    Lab,
    Authorization,
    DataDonation,
    NotificationCenter,
    WebPush
  }

  alias Core.Repo

  def valid_user_password, do: Faker.Util.format("%5d%5a%5A#")

  def build(:member) do
    %User{
      email: Faker.Internet.email(),
      hashed_password: Bcrypt.hash_pwd_salt(valid_user_password()),
      displayname: Faker.Person.first_name(),
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end

  def build(:researcher) do
    :member
    |> build(%{researcher: true})
    |> struct!(%{
      profile: %Profile{
        fullname: Faker.Person.name()
      }
    })
  end

  def build(:student) do
    :member
    |> build(%{student: true})
    |> struct!(%{
      profile: %Profile{
        fullname: Faker.Person.name()
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

  def build(:study) do
    %Studies.Study{
      auth_node: build(:auth_node),
      description: Faker.Lorem.paragraph(),
      title: Faker.Lorem.sentence()
    }
  end

  def build(:author) do
    %Studies.Author{
      fullname: Faker.Person.name(),
      displayname: Faker.Person.first_name()
    }
  end

  def build(:survey_tool_participant) do
    build(
      :survey_tool_participant,
      %{
        survey_tool: build(:survey_tool),
        user: build(:member),
        auth_node: build(:auth_node)
      }
    )
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

  def build(:participant) do
    %Survey.Participant{}
  end

  def build(:promotion) do
    %Promotions.Promotion{
      title: Faker.Lorem.sentence()
    }
  end

  def build(:criteria) do
    %Pools.Criteria{}
  end

  def build(:content_node) do
    %Content.Node{ready: true}
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

    %NotificationCenter.Box{}
    |> struct!(
      Map.delete(attributes, :user)
      |> Map.put(:auth_node, auth_node)
    )
  end

  def build(:author, %{} = attributes) do
    {researcher, attributes} = Map.pop(attributes, :researcher)
    {study, _attributes} = Map.pop(attributes, :study)

    build(:author)
    |> struct!(%{
      user: researcher,
      study: study
    })
  end

  def build(:study, %{} = attributes) do
    build(:study)
    |> struct!(%{
      authors: many_relationship(:authors, attributes)
    })
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

  def build(:content_node, %{} = attributes) do
    %Content.Node{}
    |> struct!(attributes)
  end

  def build(:submission, %{} = attributes) do
    {parent_content_node, _attributes} = Map.pop!(attributes, :parent_content_node)
    content_node = build(:content_node, %{parent: parent_content_node})

    %Pools.Submission{
      status: :idle,
      criteria: build(:criteria),
      pool: Pools.get_by_name(:vu_students),
      content_node: content_node
    }
  end

  def build(:promotion, %{} = attributes) do
    {study, attributes} = Map.pop!(attributes, :study)
    {parent_content_node, attributes} = Map.pop!(attributes, :parent_content_node)

    content_node = build(:content_node, %{parent: parent_content_node})

    %Promotions.Promotion{
      title: Faker.Lorem.sentence(),
      content_node: content_node,
      auth_node: build(:auth_node, %{parent: study.auth_node}),
      submission: build(:submission, %{parent_content_node: content_node})
    }
    |> struct!(attributes)
  end

  def build(:data_donation_tool, %{} = attributes) do
    {content_node, attributes} = Map.pop(attributes, :content_node, build(:content_node, %{}))
    {study, attributes} = Map.pop(attributes, :study, build(:study))

    {promotion, attributes} =
      Map.pop(
        attributes,
        :promotion,
        build(:promotion, %{study: study, parent_content_node: content_node})
      )

    %DataDonation.Tool{
      content_node: content_node,
      auth_node: build(:auth_node, %{parent: study.auth_node}),
      study: study,
      promotion: promotion
    }
    |> struct!(attributes)
  end

  def build(:survey_tool_participant, %{} = attributes) do
    survey_tool = Map.get(attributes, :survey_tool, build(:survey_tool))
    user = Map.get(attributes, :user, build(:member))

    %Survey.Participant{
      survey_tool: survey_tool,
      user: user
    }
  end

  def build(:survey_tool, %{} = attributes) do
    {content_node, attributes} = Map.pop(attributes, :content_node, build(:content_node, %{}))
    {study, attributes} = Map.pop(attributes, :study, build(:study))

    {promotion, attributes} =
      Map.pop(
        attributes,
        :promotion,
        build(:promotion, %{study: study, parent_content_node: content_node})
      )

    %Survey.Tool{
      content_node: content_node,
      auth_node: build(:auth_node, %{parent: study.auth_node}),
      study: study,
      promotion: promotion
    }
    |> struct!(attributes)
  end

  def build(:lab_tool, %{} = attributes) do
    {content_node, attributes} = Map.pop(attributes, :content_node, build(:content_node, %{}))
    {study, attributes} = Map.pop(attributes, :study, build(:study))

    {promotion, attributes} =
      Map.pop(
        attributes,
        :promotion,
        build(:promotion, %{study: study, parent_content_node: content_node})
      )

    %Lab.Tool{
      content_node: content_node,
      auth_node: build(:auth_node, %{parent: study.auth_node}),
      study: study,
      promotion: promotion
    }
    |> struct!(attributes)
  end

  def build(factory_name, %{} = attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name) do
    insert!(factory_name, %{})
  end

  def insert!(:survey_tool_task, %{} = attributes) do
    %{survey_tool: survey_tool, user: member} = insert!(:survey_tool_participant)

    %Survey.Task{
      user: member,
      tool: survey_tool,
      status: :pending
    }
    |> struct!(attributes)
    |> Repo.insert!()
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
