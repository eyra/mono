# `Systems.Alliance.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/alliance/_public.ex#L1)

Alliance tools allow a researcher to setup a link to an external web
tool. The participant goes through the flow described below:

- Receive invitation to start a alliance (mail, push etc.).
- Open alliance tool, this opens it on the platform and requires authentication.
- The participant is then redirected to the alliance at a 3rd party web-application.
- After completion the user is redirect back to the platform.
- The platform registers the completion of this alliance for the participant.

A researcher is required to configure the 3rd party application with a redirect
link. The redirect link to be used is show on the alliance tool configuration
screen (with copy button).

IDEA: The tool requires a sucessful round-trip with a verify flow to ensure
that everything is configured correctly.

Participants need to be invited to a particular alliance explicitly. This avoids
the situation where a new user joins a study and then can immediately complete
previous alliances.

Once a participant has completed a alliance they are no longer allowed to enter it
a second time. The status is clearly shown when the attempt to do so.

IDEA: A list of alliances can be access by the notification icon which is shown
on all screens.

# `auth_module`

# `change_tool`

Returns an `%Ecto.Changeset{}` for tracking alliance_tool changes.

# `copy`

# `delete_tool`

Deletes a alliance_tool.

# `get_tool`

# `get_tool!`

Gets a single alliance_tool.

Raises `Ecto.NoResultsError` if the Alliance tool does not exist.

# `list_tools`

Returns the list of alliance_tools.

# `prepare_tool`

Creates a alliance_tool.

# `print_auth_roles`

# `ready?`

# `update_tool`

# `update_tool`

Updates a alliance_tool.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
