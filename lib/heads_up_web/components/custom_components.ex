defmodule HeadsUpWeb.CustomComponents do
  use HeadsUpWeb, :html

  def badge(assigns) do
    ~H"""
    <div class={[
      "rounded-md px-2 py-1 text-xs font-medium uppercase inline-block border",
      @status == :resolved && "text-lime-600 border-lime-600",
      @status == :pending && "text-amber-600 border-amber-600",
      @status == :canceled && "text-gray-600 border-gray-600"
    ]}>
      {@status}
    </div>
    """
  end

  slot :inner_block, required: true
  slot :taglines

  def headline(assigns) do
    ~H"""
    <div class="headline">
      <h1>{render_slot(@inner_block)}</h1>
      <div class="tagline"></div>
      <div :for={tagline <- @taglines} class="tagline">
        {render_slot(tagline)}
      </div>
    </div>
    """
  end
end
