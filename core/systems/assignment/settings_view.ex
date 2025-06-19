defmodule Systems.Assignment.SettingsView do
  use CoreWeb, :live_component

  alias Systems.Affiliate
  alias Systems.Assignment

  @impl true
  def update(
        %{
          id: id,
          entity: assignment,
          project_node: project_node,
          storage_endpoint: storage_endpoint,
          uri_origin: uri_origin,
          viewport: viewport,
          breakpoint: breakpoint,
          title: title,
          content_flags: content_flags
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: assignment,
        project_node: project_node,
        storage_endpoint: storage_endpoint,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint,
        title: title,
        content_flags: content_flags
      )
      |> compose_child(:general)
      |> compose_child(:branding)
      |> compose_child(:information)
      |> compose_child(:privacy)
      |> compose_child(:consent)
      |> compose_child(:helpdesk)
    }
  end

  @impl true
  def compose(:general, %{
        entity: %{info: info},
        viewport: viewport,
        breakpoint: breakpoint,
        content_flags: content_flags
      }) do
    %{
      module: Assignment.GeneralForm,
      params: %{
        entity: info,
        viewport: viewport,
        breakpoint: breakpoint,
        content_flags: content_flags
      }
    }
  end

  @impl true
  def compose(:branding, %{content_flags: %{branding: false}}), do: nil

  @impl true
  def compose(:branding, %{entity: %{info: info}, viewport: viewport, breakpoint: breakpoint}) do
    %{
      module: Assignment.BrandingForm,
      params: %{
        entity: info,
        viewport: viewport,
        breakpoint: breakpoint
      }
    }
  end

  @impl true
  def compose(:information, %{content_flags: %{information: false}}), do: nil

  @impl true
  def compose(:information, %{entity: assignment}) do
    %{
      module: Assignment.ContentPageForm,
      params: %{
        assignment: assignment,
        page_key: :assignment_information,
        opt_in?: false,
        on_text: dgettext("eyra-assignment", "intro_form.on.label"),
        off_text: dgettext("eyra-assignment", "intro_form.off.label")
      }
    }
  end

  @impl true
  def compose(:privacy, %{content_flags: %{privacy: false}}), do: nil

  @impl true
  def compose(:privacy, %{entity: assignment, uri_origin: uri_origin}) do
    %{
      module: Assignment.PrivacyForm,
      params: %{
        entity: assignment,
        uri_origin: uri_origin
      }
    }
  end

  @impl true
  def compose(:consent, %{content_flags: %{consent: false}}), do: nil

  @impl true
  def compose(:consent, %{entity: assignment}) do
    %{
      module: Assignment.GdprForm,
      params: %{
        entity: assignment
      }
    }
  end

  @impl true
  def compose(:helpdesk, %{content_flags: %{helpdesk: false}}), do: nil

  @impl true
  def compose(:helpdesk, %{entity: assignment}) do
    %{
      module: Assignment.ContentPageForm,
      params: %{
        assignment: assignment,
        page_key: :assignment_helpdesk,
        opt_in?: false,
        on_text: dgettext("eyra-assignment", "support_form.on.label"),
        off_text: dgettext("eyra-assignment", "support_form.off.label")
      }
    }
  end

  @impl true
  def compose(:affiliate, %{content_flags: %{affiliate: false}}), do: nil

  @impl true
  def compose(:affiliate, %{entity: assignment}) do
    %{
      module: Affiliate.Form,
      params: %{
        assignment: assignment
      }
    }
  end

  @impl true
  def handle_event("finish", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= @title %></Text.title2>
        <.spacing value="L" />

        <.child name={:general} fabric={@fabric} >
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

        <.child name={:branding} fabric={@fabric} >
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

        <.child name={:information} fabric={@fabric} >
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.intro.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.intro.body") %></Text.body>
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

        <.child name={:privacy} fabric={@fabric} >
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.privacy.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.privacy.body") %></Text.body>
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

        <.child name={:consent} fabric={@fabric} >
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.consent.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.consent.body") %></Text.body>
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

        <.child name={:helpdesk} fabric={@fabric} >
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.support.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.support.body") %></Text.body>
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

      </Area.content>
    </div>
    """
  end
end
