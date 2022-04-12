defmodule PopulateWebRequestTables do
  import Ecto.Query
  alias Dave.Repo

  # c "#{:code.priv_dir(:dave)}/scripts/populate_web_request_tables.exs"
  @regex ~r|^.*request_id=.*\[.*\] (?<http_verb>[A-Z]+) (?<request_path>[^\s]+).*|

  def run do
    now = DateTime.utc_now()

    :dave
    |> Application.get_env(:web_server_log_file)
    |> Keyword.fetch!(:location)
    |> File.read!()
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, acc ->
      case Regex.named_captures(@regex, line) do
        nil ->
          acc

        request ->
          Map.update(acc, request, 1, fn count -> count + 1 end)
      end
    end)
    |> Enum.each(fn {%{"http_verb" => http_verb, "request_path" => request_path}, count} ->
      {1, [%{id: incoming_web_request_id}]} =
        Repo.insert_all(
          "incoming_web_requests",
          [
            %{http_method: http_verb, path: request_path, inserted_at: now, updated_at: now}
          ],
          returning: [:id]
        )

      Enum.each(1..count, fn _ ->
        Repo.insert_all("incoming_web_request_incidents", [
          %{incoming_web_request_id: incoming_web_request_id, historical: true}
        ])
      end)
    end)
  end
end
