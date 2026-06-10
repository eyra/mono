workspace "Eyra ↔ Centerdata integration" "OIDC sign-in, provisioning, and Quest launch — covering web and the hybrid Next mobile app." {

  model {
    participant = person "LISS Participant" "Signs in via LISS panel; completes Quest questionnaires"
    cdOps       = person "Centerdata Operator" "Operates provisioning of LISS panelists into Next"
    eyraOps     = person "Eyra Operator" "Configures the LISS IdP integration"

    next = softwareSystem "Eyra Next" "Research platform — web + hybrid mobile app, LiveView-based" {
      phx = container "Phoenix" "LiveView UI + OIDC RP + Provisioning API + Quest launch" "Elixir / Phoenix"
      pg  = container "Postgres" "User, assignment, and integration state" "PostgreSQL 15+" "Database"
    }

    centerdata = softwareSystem "Centerdata" "Operates the LISS panel; exposes provisioning, OIDC, and Quest endpoints to Eyra (internal architecture opaque to Eyra)" "External"

    surfconext = softwareSystem "SurfConext IdP" "OIDC IdP for academic SSO — existing integration, shown for context" "External"
    google     = softwareSystem "Google Sign-In" "OIDC IdP — existing integration, shown for context" "External"

    eyraOps -> phx "Configures IdPs and clients"
    cdOps   -> centerdata "Operates"

    participant -> phx        "Uses (web browser or mobile shell)" "HTTPS"
    phx         -> participant "Renders UI, redirects"             "HTTPS"

    participant -> centerdata "Authenticates at LISS IdP; completes questionnaires in Quest" "HTTPS"
    centerdata  -> participant "Auth UI, questionnaire UI, redirects"                        "HTTPS"

    phx        -> centerdata "OIDC sign-in (Authorization Code + PKCE)"      "OIDC / HTTPS"
    centerdata -> phx        "ID token + access token"                       "OIDC / HTTPS"

    phx        -> centerdata "Quest launch (signed JWT URL)"                 "HTTPS"
    centerdata -> phx        "Quest completion (signed payload — redirect + webhook)" "HTTPS"

    centerdata -> phx        "Provisioning (pre-register users + assignments)" "REST/JSON, OAuth 2.0 client_credentials"
    phx        -> centerdata "Access tokens, API responses"                    "REST/JSON"

    phx -> surfconext "Authenticates academic users (existing)" "OIDC"
    phx -> google     "Authenticates Google users (existing)"   "OIDC"

    phx -> pg "Reads/writes" "SQL/TLS"
  }

  views {
    systemContext next "Context" "Who participates and which external systems Next integrates with. Centerdata is one IdP among several; SurfConext and Google shown for context." {
      include *
      autolayout lr
    }

    dynamic next "Provisioning" "Interface 1 — Centerdata pre-registers a LISS panelist and an assignment in Next, before the participant ever signs in." {
      centerdata -> phx "[Provisioning] POST /oauth/token (client_credentials)"
      phx        -> centerdata "[Provisioning] Access token (Bearer, short-lived)"
      centerdata -> phx "[Provisioning] POST /api/centerdata/v1/users {liss_sub, email, ...}"
      phx        -> pg  "Insert pre-registered user"
      phx        -> centerdata "[Provisioning] 201 Created"
      centerdata -> phx "[Provisioning] POST /api/centerdata/v1/assignments"
      phx        -> pg  "Insert assignment"
      phx        -> centerdata "[Provisioning] 201 Created"
      autolayout tb
    }

    dynamic next "SignIn" "Interface 2 — A LISS participant signs in via OIDC. Identical for web and mobile." {
      participant -> phx        "Clicks 'Log in with LISS'"
      phx         -> participant "302 Redirect to LISS IdP /authorize (code + PKCE)"
      participant -> centerdata "[LISS IdP] Follows redirect; authenticates"
      centerdata  -> participant "[LISS IdP] 302 Redirect to /auth/liss/callback with code"
      participant -> phx        "GET /auth/liss/callback?code=..."
      phx         -> centerdata "[LISS IdP] POST /token (code + PKCE verifier)"
      centerdata  -> phx        "[LISS IdP] id_token + access_token"
      phx         -> pg         "Lookup user by id_token.sub == liss_sub"
      phx         -> participant "Session established; redirect to LiveView"
      autolayout tb
    }

    dynamic next "QuestLaunch" "Interface 3 — A signed-in participant launches a Quest questionnaire." {
      participant -> phx        "Taps 'Start' on Quest assignment"
      phx         -> participant "302 Redirect to Quest launch URL (signed JWT)"
      participant -> centerdata "[Quest] Follows redirect; completes questionnaire"
      centerdata  -> participant "[Quest] 302 Redirect to return_url (signed completion)"
      participant -> phx        "GET return_url"
      centerdata  -> phx        "[Quest] Webhook: POST /quest/completion (signed)"
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
