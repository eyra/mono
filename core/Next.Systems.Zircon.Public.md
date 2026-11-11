# `Next.Systems.Zircon.Public`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/zircon/_public.ex#L1)

# `abort_active_imports!`

Aborts any active import sessions for the tool and archives all uploaded reference files.
This clears the file selector and stops any ongoing imports.

# `abort_import!`

Aborts an import by cancelling the session and archiving its reference file.
This completely cleans up the import, removing it from the file selector.

# `auth_module`

# `cleanup_reference_files_for_new_upload!`

Cleans up all reference files for a tool before uploading a new file.
This aborts any active imports and archives all uploaded files.

# `delete_screening_tool_criterion`

# `get_latest_uploaded_reference_file`

Gets the latest uploaded reference file for a tool.
Returns a map with :file (the reference file) and :file_info (filename and url).
Returns nil if no uploaded file exists.

# `get_screening_session`

# `get_screening_tool!`

# `get_screening_tool_by_reference_file!`

# `get_uploaded_reference_file_ids`

Gets all uploaded reference files for a tool.
Returns a list of reference file IDs that have :uploaded status.

# `insert_reference_file`

# `insert_reference_file`

# `insert_reference_file!`

  Inserts a new paper reference file associated with the given screening tool.

# `insert_reference_file!`

# `insert_screening_tool_criterion`

# `invalidate_screening_sessions`

# `list_papers`

# `list_reference_files`

# `list_screening_tool_reference_files`

# `obtain_screening_session`

# `obtain_screening_session!`

# `obtain_screening_tool_annotation`

# `obtain_screening_tool_annotation!`

# `obtain_screening_tool_annotations`

# `prepare_screening_session`

# `prepare_screening_tool`

  Creates a screening tool without saving.

# `prepare_screening_tool_reference_file_assoc`

  Creates an association between the given screening tool and the paper reference file at
  the given url without saving.

# `print_auth_roles`

# `start_screening_session`

# `start_screening_session!`

# `update_screening_session`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
