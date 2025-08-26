defmodule Next.Account.ParticipantSigninView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Line
  import Systems.Account.UserForm

  alias Systems.Account.User

  @impl true
  def update(%{blocks: blocks, email: email, status: status}, socket) do
    {
      :ok,
      socket
      |> assign(email: email, blocks: blocks, status: status)
      |> update_password_form()
    }
  end

  defp update_password_form(%{assigns: %{email: email}} = socket) do
    attrs =
      if User.valid_email?(email) do
        %{"email" => email}
      else
        %{}
      end

    assign(socket, :password_form, to_form(attrs))
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <%= for block <- @blocks do %>
          <%= if block == :google do %>
            <.google_signin creator?={false} />
          <% end %>
          <%= if block == :password do %>
            <.password_signin for={@password_form} user_type={:participant} status={@status}/>
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
