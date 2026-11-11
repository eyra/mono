# `Systems.Feldspar.DataDonationFolder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/feldspar/data_donation_folder.ex#L1)

Manages a folder of data donation files.

Files are stored in a configurable directory with a unique ID and .dat extension.
This avoids memory pressure from large uploads by storing data on the filesystem.

# `cleanup_older_than`

Deletes all files older than the given number of hours.
Returns the count of deleted files.

# `delete`

Deletes a data donation file. Only used by the cleanup worker.

# `filename`

Generates a unique filename from context map for temporary storage.

# `list_all`

Lists all data donation files with their metadata.
Returns a list of %{id: file_id, path: full_path, size: bytes, created_at: DateTime}.

# `read`

Reads a data donation file from the filesystem.
Returns {:ok, data} or {:error, reason}.

# `size`

Returns the size of a data donation file, or 0 if not found.

# `stats`

Returns aggregate statistics about stored data donations.

# `store`

Stores data as a file with the given file_id.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
