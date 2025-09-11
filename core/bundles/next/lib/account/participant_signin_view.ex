defmodule Next.Account.ParticipantSigninView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Line
  import Systems.Account.UserForm

  alias Systems.Account.User

  @impl true
  def update(%{blocks: blocks, email: email, status: status} = params, socket) do
    post_signin_action = Map.get(params, :post_signin_action)

    {
      :ok,
      socket
      |> assign(
        email: email,
        blocks: blocks,
        status: status,
        post_signin_action: post_signin_action
      )
      |> update_password_form()
    }
  end

  defp update_password_form(
         %{assigns: %{email: email, post_signin_action: post_signin_action}} = socket
       ) do
    attrs =
      if User.valid_email?(email) do
        %{"email" => email}
      else
        %{}
      end

    form =
      if post_signin_action do
        Map.put(attrs, "post_signin_action", post_signin_action) |> to_form()
      else
        to_form(attrs)
      end

    socket |> assign(:password_form, form)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <%= for block <- @blocks do %>
          <%= if block == :google do %>
            <.google_signin creator?={false} post_signin_action={@post_signin_action} />
          <% end %>
          <%= if block == :password do %>
            <.password_signin for={@password_form} user_type={:participant} status={@status} post_signup_action={@post_signin_action} />
          <% end %>
          <%= if block == :seperator do %>
            <.spacing value="M" />
            <.line />
            <.spacing value="M" />
          <% end %>
        <% end %>
      </div>
    """
  end
end
