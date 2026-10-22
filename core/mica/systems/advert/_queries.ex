defmodule Systems.Advert.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Advert
  alias Systems.Account

  def advert_query() do
    from(Advert.Model, as: :advert)
  end

  def advert_query(status) do
    build(advert_query(), :advert, [
      status == ^status
    ])
  end

  def advert_query(%Account.User{id: user_id}, :participant) do
    build(advert_query(), :advert,
      assignment: [
        crew: [
          auth_node: [
            role_assignments: [
              role == :participant,
              principal_id == ^user_id
            ]
          ]
        ]
      ]
    )
  end
end
