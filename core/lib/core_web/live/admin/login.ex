defmodule CoreWeb.Admin.Login do
  use CoreWeb, :live_view
  import Ecto.Query
  alias Core.Repo
  alias Core.Accounts.User
  alias Core.Accounts

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
    <div class="flex flex-row h-screen w-full">
      <div class="w-1 md:w-sidepadding flex-shrink-0"> </div>
      <div class="flex-2">
        <div class="flex flex-col h-full w-full">
          <div class="h-topbar sm:h-topbar-sm lg:h-topbar-lg pl-7 md:pl-0" >
            <div class="flex flex-row h-full">
              <div class="flex-wrap">
                <div class="flex flex-col items-center justify-center h-full">
                  <div class="flex-wrap cursor-pointer">
                    <a
                      class="cursor-pointer"
                      data-phx-link="redirect"
                      data-phx-link-state="replace"
                      href="/"
                    >
                      <img class="w-9 h-8 sm:w-12 sm:h-12" src={{ Routes.static_path(@socket, "/images/icons/eyra.svg") }} />
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="flex-grow">
            <div class="flex flex-col h-full bg-white border-t border-l border-b border-grey3">
              <div class="flex-grow md:pr-sidepadding">
                <div class="w-full">

                  <div class="flex justify-center">
                    <div class="flex-grow max-w-form ml-7 mr-6 lg:m-0 pt-6 md:pt-9 lg:pt-20">

                      <div class="text-title4 font-title5 sm:text-title3 sm:font-title3 lg:text-title2 lg:font-title2 mb-7 lg:mb-9">
                        Log in
                      </div>

                      <div class="mb-7"></div>

                      <a href={{Routes.google_sign_in_path(@socket, :core, return_to: "/admin/coordinator-management")}}>
                        <div class="pt-3px pb-2px active:pt-3px active:pb-1px active:shadow-top4px bg-google rounded pl-4 pr-4">
                          <div class="flex w-full justify-center items-center">
                            <div>
                              <img class="mr-4 -mt-1" src="/images/google.svg">
                            </div>
                            <div class="h-12 focus:outline-none">
                              <div class="flex flex-col justify-center h-full items-center rounded">
                                <div class="text-white text-button font-button">
                                  Meld je aan met Google
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </a>

                      <div class="mb-7"></div>

                    </div>
                  </div>
                </div>
              </div>
              <div class="bg-white">
              {{ footer Routes.static_path(@socket, "/images/footer-left.svg"), Routes.static_path(@socket, "/images/footer-right.svg") }}
              </div>
            </div>
          </div>
          <div class="pb-1 md:pb-10 bg-grey5">
          </div>
        </div>
      </div>
    </div>
    """
  end
end
