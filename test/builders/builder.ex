defmodule Dave.Builder do
  alias Dave.Repo

  def insert(resource, table_name, opts \\ []) do
    resource = add_timestamps(resource)
    returning = parse_columns_to_return(opts[:returning])

    {1, [returned_columns]} = Repo.insert_all(table_name, [resource], returning: returning)

    if returning == [:id] do
      returned_columns.id
    else
      returned_columns
    end
  end

  defp parse_columns_to_return(nil) do
    [:id]
  end

  defp parse_columns_to_return(returning) do
    if Enum.member?(returning, :id) do
      returning
    else
      [:id | returning]
    end
  end

  defp add_timestamps(resource) do
    now = DateTime.utc_now()
    timestamps = %{inserted_at: now, updated_at: now}

    Map.merge(timestamps, resource)
  end
end
