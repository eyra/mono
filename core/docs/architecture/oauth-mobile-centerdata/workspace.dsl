workspace "Eyra ↔ Centerdata integration" "OIDC sign-in, provisioning, and external questionnaire launch — covering web and the hybrid Next mobile app." {

  model {
    participant = person "LISS Participant" "Signs in via Centerdata; completes Centerdata-hosted questionnaires"
    cdOps       = person "Centerdata Operator" "Operates provisioning of LISS panelists into Next"
    eyraOps     = person "Eyra Operator" "Configures the Centerdata OIDC integration"

    next = softwareSystem "Eyra Next" "Research platform — web + hybrid mobile app, LiveView-based" {
      phx = container "Phoenix" "LiveView UI + OIDC RP + Provisioning API + Questionnaire launch" "Elixir / Phoenix"
      pg  = container "Postgres" "User, assignment, and integration state" "PostgreSQL 15+" "Database"
    }

    centerdata = softwareSystem "Centerdata" "Operates the LISS panel; exposes provisioning, OIDC, and questionnaire endpoints to Eyra (internal architecture opaque to Eyra)" "External"

    eyraOps -> phx "Configures IdPs and clients"
    cdOps   -> centerdata "Operates"

    participant -> phx        "Uses (web browser or mobile shell)" "HTTPS"
    phx         -> participant "Renders UI, redirects"             "HTTPS"

    participant -> centerdata "Authenticates and completes questionnaires" "HTTPS"
    centerdata  -> participant "Auth UI, questionnaire UI, redirects"      "HTTPS"

    phx        -> centerdata "OIDC sign-in (Authorization Code + PKCE)"      "OIDC / HTTPS"
    centerdata -> phx        "ID token + access token"                       "OIDC / HTTPS"

    phx        -> centerdata "Questionnaire launch (signed JWT URL)"                 "HTTPS"
    centerdata -> phx        "Questionnaire completion (signed payload — redirect + webhook)" "HTTPS"

    centerdata -> phx        "Provisioning (pre-register users + assignments)" "REST/JSON, OAuth 2.0 client_credentials"
    phx        -> centerdata "Access tokens, API responses"                    "REST/JSON"

    phx -> pg "Reads/writes" "SQL/TLS"
  }

  views {
    systemContext next "Context" "Who participates and which external party Next integrates with for the Centerdata integration." {
      include *
      autolayout lr
    }

    dynamic next "Provisioning" "Interface 1 — Centerdata pre-registers a LISS panelist and an assignment in Next, before the participant ever signs in." {
      centerdata -> phx "POST /oauth/token (client_credentials)"
      phx        -> centerdata "Access token (Bearer, short-lived)"
      centerdata -> phx "POST /api/centerdata/v1/users {sub, email, ...}"
      phx        -> pg  "Insert pre-registered user"
      phx        -> centerdata "201 Created"
      centerdata -> phx "POST /api/centerdata/v1/assignments"
      phx        -> pg  "Insert assignment"
      phx        -> centerdata "201 Created"
      autolayout tb
    }

    dynamic next "SignIn" "Interface 2 — A LISS participant signs in via OIDC. Identical for web and mobile." {
      participant -> phx        "Clicks 'Log in with LISS'"
      phx         -> participant "302 Redirect to Centerdata /authorize (code + PKCE)"
      participant -> centerdata "Follows redirect; authenticates"
      centerdata  -> participant "302 Redirect to /auth/liss/callback with code"
      participant -> phx        "GET /auth/liss/callback?code=..."
      phx         -> centerdata "POST /token (code + PKCE verifier)"
      centerdata  -> phx        "id_token + access_token"
      phx         -> pg         "Lookup user by id_token.sub"
      phx         -> participant "Session established; redirect to LiveView"
      autolayout tb
    }

    dynamic next "QuestionnaireLaunch" "Interface 3 — A signed-in participant launches an external Centerdata-hosted questionnaire." {
      participant -> phx        "Taps 'Start' on questionnaire assignment"
      phx         -> participant "302 Redirect to questionnaire launch URL (signed JWT)"
      participant -> centerdata "Follows redirect; completes questionnaire"
      centerdata  -> participant "302 Redirect to return_url (signed completion)"
      participant -> phx        "GET return_url"
      centerdata  -> phx        "Webhook: POST /questionnaire/completion (signed)"
      phx         -> pg         "Record completion"
      autolayout tb
    }

    styles {
      element "Person" {
        background "#FF5E5E"
        color "#FFFFFF"
        shape Person
      }
      element "Software System" {
        background "#4272EF"
        color "#FFFFFF"
      }
      element "Container" {
        background "#4272EF"
        color "#FFFFFF"
      }
      element "External" {
        background "#FFCF60"
        color "#222222"
      }
      element "Database" {
        shape Cylinder
      }
    }

    theme default
  }
}
