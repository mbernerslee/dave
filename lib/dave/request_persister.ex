defmodule Dave.RequestPersister do
  require Logger
  import Ecto.Query
  alias Dave.Repo

  def save_in_db(path, http_method) do
    case validate_path(path) do
      {:ok, path} -> perform_database_updates(path, http_method)
      :error -> :error
    end
  end

  defp validate_path(path) do
    if String.length(path) > 2000 do
      Logger.error("A web request came in for a path longer that 2000 characters")
      :error
    else
      {:ok, path}
    end
  end

  defp perform_database_updates(path, http_method) do
    now = DateTime.utc_now()
    incoming_web_request_id = upsert_incoming_web_request(path, http_method, now)
    insert_new_incoming_web_request_incident(incoming_web_request_id, now)
    {:ok, %{path: path, http_method: http_method}}
  end

  defp insert_new_incoming_web_request_incident(incoming_web_request_id, now) do
    {1, nil} =
      Repo.insert_all(
        "incoming_web_request_incidents",
        [
          %{
            incoming_web_request_id: incoming_web_request_id,
            historical: false,
            inserted_at: now,
            updated_at: now
          }
        ]
      )
  end

  defp upsert_incoming_web_request(path, http_method, now) do
    case get_incoming_web_request(path, http_method) do
      nil -> insert_new_incoming_web_request(path, http_method, now)
      id -> id
    end
  end

  defp get_incoming_web_request(path, http_method) do
    Repo.one(
      from i in "incoming_web_requests",
        where: i.path == ^path and i.http_method == ^http_method,
        select: i.id
    )
  end

  defp insert_new_incoming_web_request(path, http_method, now) do
    {1, [%{id: incoming_web_request_id}]} =
      Repo.insert_all(
        "incoming_web_requests",
        [%{http_method: http_method, path: path, inserted_at: now, updated_at: now}],
        returning: [:id]
      )

    incoming_web_request_id
  end
end
