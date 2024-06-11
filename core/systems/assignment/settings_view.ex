defmodule Systems.Assignment.SettingsView do
  use CoreWeb, :live_component

  alias Systems.Assignment

  @impl true
  def update(
        %{
          id: id,
          entity: assignment,
          template: template,
          uri_origin: uri_origin,
          viewport: viewport,
          breakpoint: breakpoint
        },
        socket
      ) do
    content_flags = Assignment.Template.content_flags(template)

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: assignment,
        content_flags: content_flags,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> compose_child(:general)
      |> compose_child(:branding)
      |> compose_child(:information)
      |> compose_child(:privacy)
      |> compose_child(:consent)
      |> compose_child(:helpdesk)
      |> compose_child(:panel)
      |> compose_child(:storage)
    }
  end

  @impl true
  def compose(:general, %{content_flags: %{general: false}}), do: nil

  @impl true
  def compose(:general, %{entity: %{info: info}, viewport: viewport, breakpoint: breakpoint}) do
    %{
      module: Assignment.GeneralForm,
      params: %{
        entity: info,
        viewport: viewport,
        breakpoint: breakpoint
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
  def compose(:panel, %{content_flags: %{panel: false}}), do: nil

  @impl true
  def compose(:panel, %{entity: assignment, uri_origin: uri_origin}) do
    %{
      module: Assignment.ConnectorView,
      params: %{
        assignment: assignment,
        connection: assignment.external_panel,
        type: :panel,
        uri_origin: uri_origin
      }
    }
  end

  @impl true
  def compose(:storage, %{content_flags: %{storage: false}}), do: nil

  @impl true
  def compose(:storage, %{entity: assignment, uri_origin: uri_origin}) do
    %{
      module: Assignment.ConnectorView,
      params: %{
        assignment: assignment,
        connection: assignment.storage_endpoint,
        type: :storage,
        uri_origin: uri_origin
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
        <Text.title2><%= dgettext("eyra-assignment", "settings.title") %></Text.title2>
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

        <.child name={:panel} fabric={@fabric}>
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.panel.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.panel.body") %></Text.body>
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

        <.child name={:storage} fabric={@fabric}>
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.data_storage.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.data_storage.body") %></Text.body>
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
