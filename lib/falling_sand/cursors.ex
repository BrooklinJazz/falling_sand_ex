defmodule FallingSand.Cursors do
  @name :cursors
  def new(opts \\ []) do
    name = Keyword.get(opts, :name, @name)
    :ets.new(name, [:named_table, :set, :public])
  end

  @spec put(atom() | :ets.tid(), FallingSand.cell()) :: true
  def put(name \\ @name, page_id, cell) do
    :ets.insert(name, {page_id, cell})
  end

  def all_cursors(name \\ @name) do
    :ets.tab2list(name)
  end
end
