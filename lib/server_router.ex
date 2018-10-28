defmodule Server.Router do
  use Plug.Router

  plug Plug.Static, at: "/", from: "static"
  plug :match
  plug :dispatch

  match _ do
    send_resp(conn, 200,
      """
        <h1>PREPARE</h1>
        <h2>FOR WEIRD SQUARE</h2>
        <script>
        document.location = "/index.html"
        </script>
      """)
  end
end
