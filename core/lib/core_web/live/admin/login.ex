defmodule CoreWeb.Admin.Login do
  use CoreWeb, :live_view
  import Ecto.Query
  alias Core.Repo
  alias Core.Accounts.User
  alias Core.Accounts

  alias CoreWeb.Layouts.Stripped.Component, as: Stripped

  data(users, :any)

  def mount(_params, _session, socket) do
    {
      :ok,
      socket |> assign(:users, list_users())
    }
  end

  # FIXME: Move this to Accounts
  defp list_users do
    from(u in User, order_by: {:asc, :email})
    |> Repo.all()
  end

  def handle_event("assign_coorinator_role", %{"email" => email}, socket) do
    user = Accounts.get_user_by_email(email)
    Accounts.update_user_profile(user, %{coordinator: true}, %{})
    {:noreply, socket |> assign(:users, list_users())}
  end

  def handle_event("remove_coorinator_role", %{"email" => email}, socket) do
    user = Accounts.get_user_by_email(email)
    Accounts.update_user_profile(user, %{coordinator: false}, %{})
    {:noreply, socket |> assign(:users, list_users())}
  end

  def render(assigns) do
    ~H"""
    <Stripped
      user={{@current_user}}
      active_item={{ :dashboard }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
          <FormArea>
            <div class="text-title5 font-title5 sm:text-title3 sm:font-title3 lg:text-title2 lg:font-title2 mb-7 lg:mb-9">
              Log in
            </div>
            <div class="mb-6"></div>
              <a href="/google-sign-in">
                <div class="pt-2px pb-2px active:pt-3px active:pb-1px active:shadow-top4px bg-grey1 rounded pl-4 pr-4">
                  <div class="flex w-full justify-center items-center">
                    <div>
                      <img class="mr-3 -mt-1" src="/images/google.svg" alt="">
                    </div>
                    <div class="h-11 focus:outline-none">
                      <div class="flex flex-col justify-center h-full items-center rounded">
                        <div class="text-white text-button font-button">
                          Sign in with Eyra account
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </a>
          </FormArea>
        </ContentArea>
      </Stripped>
    """
  end
end
