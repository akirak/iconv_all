defmodule IconvAll.GitTest do
  use ExUnit.Case
  doctest IconvAll.Git

  test "greets the world" do
    assert IconvAll.Git.hello() == :world
  end
end
