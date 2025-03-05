defmodule HeadsUpWeb.TipHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use HeadsUpWeb, :html

  embed_templates "tip_html/*"
end
