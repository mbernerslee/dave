defmodule Dave.Constants do
  def http_method_get, do: "GET"
  def http_method_head, do: "HEAD"
  def http_method_post, do: "POST"
  def http_method_delete, do: "DELETE"
  def http_method_connect, do: "CONNECT"
  def http_method_options, do: "OPTIONS"
  def http_method_trace, do: "TRACE"
  def http_method_patch, do: "PATCH"

  def http_methods do
    [
      http_method_get(),
      http_method_head(),
      http_method_post(),
      http_method_delete(),
      http_method_connect(),
      http_method_options(),
      http_method_trace(),
      http_method_patch()
    ]
  end

  def pubsub_web_requests_topic do
    "web_server_requests"
  end
end
