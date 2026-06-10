workspace "Eyra ↔ Centerdata integration" "OIDC sign-in, provisioning, and Quest launch — covering web and the hybrid Next mobile app." {

  model {
    participant = person "LISS Participant" "Signs in via LISS panel; completes Quest questionnaires"
    cdOps       = person "Centerdata Operator" "Operates provisioning of LISS panelists into Next"
    eyraOps     = person "Eyra Operator" "Configures the LISS IdP integration"

    next = softwareSystem "Eyra Next" "Research platform — web + hybrid mobile app, LiveView-based" {
      phx = container "Phoenix" "LiveView UI + OIDC RP + Provisioning API + Quest launch" "Elixir / Phoenix"
      pg  = container "Postgres" "User, assignment, and integration state" "PostgreSQL 15+" "Database"
    }

    group "Centerdata" {
      lissIdp        = softwareSystem "LISS IdP"            "OIDC Authorization Server for LISS panelists"                              "External"
      quest          = softwareSystem "Quest"               "Hosts and serves web questionnaires"                                       "External"
      provisioningCd = softwareSystem "Provisioning client" "Pre-registers panelists and assignments into Next (Centerdata back office)" "External"
    }

    surfconext = softwareSystem "SurfConext IdP" "OIDC IdP for academic SSO — existing integration, shown for context" "External"
    google     = softwareSystem "Google Sign-In" "OIDC IdP — existing integration, shown for context" "External"

    eyraOps -> phx "Configures IdPs and clients"
    cdOps   -> provisioningCd "Operates"

    participant -> phx     "Uses (web browser or mobile shell)" "HTTPS"
    phx         -> participant "Renders UI, redirects"          "HTTPS"

    participant -> lissIdp "Authenticates at LISS IdP"        "HTTPS"
    lissIdp     -> participant "Auth UI + redirects with code" "HTTPS"

    participant -> quest "Completes questionnaire"           "HTTPS"
    quest       -> participant "Renders questionnaire, redirects" "HTTPS"

    phx     -> lissIdp "OIDC: token exchange (code → tokens), JWKS" "OIDC / HTTPS"
    lissIdp -> phx     "id_token + access_token"                    "OIDC / HTTPS"

    phx   -> quest "Signed launch URL (JWT)"             "HTTPS"
    quest -> phx   "Completion webhook (signed payload)" "HTTPS"

    provisioningCd -> phx "Pre-register users and assignments" "REST/JSON, OAuth 2.0 client_credentials"
    phx            -> provisioningCd "Access tokens, API responses" "REST/JSON"

    phx -> surfconext "Authenticates academic users (existing)" "OIDC"
    phx -> google     "Authenticates Google users (existing)"   "OIDC"

    phx -> pg "Reads/writes" "SQL/TLS"
  }

  views {
    systemContext next "Context" "Who participates and which external systems Next integrates with for the Centerdata integration." {
      include *
      autolayout lr
    }

    container next "Containers" "Phoenix is the single Eyra container that integrates with Centerdata — through three distinct external Centerdata systems, one per interface." {
      include *
      autolayout lr
    }

    dynamic next "Provisioning" "Interface 1 — Centerdata pre-registers a LISS panelist and an assignment in Next, before the participant ever signs in." {
      provisioningCd -> phx "POST /oauth/token (client_credentials)"
      phx            -> provisioningCd "Access token (Bearer, short-lived)"
      provisioningCd -> phx "POST /api/centerdata/v1/users {liss_sub, email, ...}"
      phx            -> pg  "Insert pre-registered user"
      phx            -> provisioningCd "201 Created"
      provisioningCd -> phx "POST /api/centerdata/v1/assignments"
      phx            -> pg  "Insert assignment"
      phx            -> provisioningCd "201 Created"
      autolayout tb
    }

    dynamic next "SignIn" "Interface 2 — A LISS participant signs in via OIDC. Identical for web and mobile." {
      participant -> phx     "Clicks 'Log in with LISS'"
      phx         -> participant "302 Redirect to LISS IdP /authorize (code + PKCE)"
      participant -> lissIdp "Follows redirect; authenticates at LISS IdP"
      lissIdp     -> participant "302 Redirect to /auth/liss/callback with code"
      participant -> phx     "GET /auth/liss/callback?code=..."
      phx         -> lissIdp "POST /token (code + PKCE verifier)"
      lissIdp     -> phx     "id_token + access_token"
      phx         -> pg      "Lookup user by id_token.sub == liss_sub"
      phx         -> participant "Session established; redirect to LiveView"
      autolayout tb
    }

    dynamic next "QuestLaunch" "Interface 3 — A signed-in participant launches a Quest questionnaire." {
      participant -> phx   "Taps 'Start' on Quest assignment"
      phx         -> participant "302 Redirect to Quest launch URL (signed JWT)"
      participant -> quest "Follows redirect; completes questionnaire"
      quest       -> participant "302 Redirect to return_url (signed completion)"
      participant -> phx   "GET return_url"
      quest       -> phx   "Webhook: POST /quest/completion (signed)"
      phx         -> pg    "Record completion"
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
