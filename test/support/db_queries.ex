defmodule Dave.Support.DBQueries do
  import Ecto.Query
  alias Dave.Repo

  def all_paths_and_methods_with_counts do
    Repo.all(
      from i in "incoming_web_requests",
        inner_join: ii in "incoming_web_request_incidents",
        on: ii.incoming_web_request_id == i.id,
        group_by: [i.path, i.http_method],
        select: {i.path, i.http_method, count(ii.id)}
    )
  end
end
