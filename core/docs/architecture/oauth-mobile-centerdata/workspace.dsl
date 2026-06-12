workspace "Next ↔ Centerdata integration" "OIDC sign-in and external questionnaire launch — covering web and the hybrid Next mobile app." {

  model {
    participant = person "LISS Participant" "Signs in via Centerdata; completes Centerdata-hosted questionnaires"
    cdOps       = person "Centerdata Operator" "Enrolls LISS panelists on Next assignments via CSV upload"
    eyraOps     = person "Eyra Operator" "Configures the Centerdata OIDC integration"

    next       = softwareSystem "Eyra Next"  "Research platform — web + hybrid mobile app, LiveView-based"
    centerdata = softwareSystem "Centerdata" "Operates the LISS panel; exposes OIDC and questionnaire endpoints to Next (internal architecture opaque)" "External"

    eyraOps -> next       "Configures IdPs and clients"
    cdOps   -> centerdata "Operates"

    participant -> next        "Uses (web browser or mobile shell)" "HTTPS"
    next        -> participant "Renders UI, redirects"              "HTTPS"

    participant -> centerdata "Authenticates and completes questionnaires" "HTTPS"
    centerdata  -> participant "Auth UI, questionnaire UI, redirects"      "HTTPS"

    next       -> centerdata "OIDC sign-in (Authorization Code + PKCE)" "OIDC / HTTPS"
    centerdata -> next       "ID token + access token"                  "OIDC / HTTPS"

    next       -> centerdata "Questionnaire launch (signed JWT URL)"                       "HTTPS"
    centerdata -> next       "Questionnaire completion (signed payload — redirect + webhook)" "HTTPS"

    cdOps -> next "Uploads CSV via Next CMS to enroll participants on an assignment" "HTTPS"
  }

  views {
    systemContext next "Context" "Who participates and which external party Next integrates with for the Centerdata integration." {
      include *
      autolayout lr
    }

    dynamic * "SignIn" "Interface 2 — A LISS participant signs in via OIDC. Identical for web and mobile." {
      participant -> next        "Clicks 'Log in with LISS'"
      next        -> participant "302 Redirect to Centerdata /authorize (code + PKCE)"
      participant -> centerdata  "Follows redirect; authenticates"
      centerdata  -> participant "302 Redirect to /auth/liss/callback with code"
      participant -> next        "GET /auth/liss/callback?code=..."
      next        -> centerdata  "POST /token (code + PKCE verifier)"
      centerdata  -> next        "id_token + access_token"
      next        -> participant "Session established; redirect to LiveView"
      autolayout tb
    }

    dynamic * "QuestionnaireLaunch" "Interface 3 — A signed-in participant launches an external Centerdata-hosted questionnaire." {
      participant -> next        "Taps 'Start' on questionnaire assignment"
      next        -> participant "302 Redirect to questionnaire launch URL (signed JWT)"
      participant -> centerdata  "Follows redirect; completes questionnaire"
      centerdata  -> participant "302 Redirect to return_url (signed completion)"
      participant -> next        "GET return_url"
      centerdata  -> next        "Webhook: POST /questionnaire/completion (signed)"
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
      element "External" {
        background "#FFCF60"
        color "#222222"
      }
    }

    theme default
  }
}
