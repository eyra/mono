defprotocol Systems.Assignment.Assignable do

  @spec languages(map) :: list
  def languages(assignable)

  @spec devices(map) :: list
  def devices(assignable)

  @spec spot_count(map) :: number
  def spot_count(assignable)

  @spec duration(map) :: number
  def duration(assignable)

  @spec path(map, number | binary) :: binary | nil
  def path(assignable, panl_id)

  @spec apply_label(map) :: binary
  def apply_label(assignable)

  @spec open_label(map) :: binary | nil
  def open_label(assignable)

end
