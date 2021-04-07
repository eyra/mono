# Sign In with Apple

Several steps need to be completed to setup Sign In with Apple. An Apple
developer account is a pre-requisite.

Go to the Apple developer portal and open the
[certificates](https://developer.apple.com/account/resources/certificates).

Once there, create an identifier. Select "App ID". Select "Sign In with Apple".
Edit it and keep "Enable as a primary App ID" enabled. Notifications
are not yet support so this field can be left blank.

Now create another identifier using the `+` icon. This time select "Service
IDs" and click continue. Enter a description and an identifier. Note down the
"Identifier". This needs to be set as the `:client_id`.

Now open the newly created service and enable Sign In with Apple. Click
configure to setup the domain and return URL. The return URL should be set to
`#{domain}/apple/auth`. Something like [ngrok](https://ngrok.com/) is required
to develop locally.

After completing the preceding step go to the "Keys" screen. There click the
`+` button to create a new key. Select the "Sign In with Apple" checkbox and
click "Configure". Make sure the proper primary App ID is selected and that the
grouped app id matches the service. Then click "Save" and "Register".

Download the key and note down the "Key ID", this will be used for the
`:private_key_id` setting.

Go to your account (profile button). There you will see the `:team_id`.

Now enter all the configuration values into the config. It should look
something like:

    config :core, SignInWithApple,
      client_id: "com.exmple.service" # the id from the service,
      team_id: "2EDL5EPQY4" # the id from the profile page,
      private_key_id: "AABBCCDDEE" # shown at the download key page,
      private_key_path: "/<full-path>/AuthKey_AABBCCDDEE.p8",
      redirect_uri: "https://example.com/apple/auth"
