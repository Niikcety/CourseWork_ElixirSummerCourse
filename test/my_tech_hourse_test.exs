defmodule MyTechHourseTest do
  use ExUnit.Case
  doctest MyTechHourse

  test "greets the world" do
    assert MyTechHourse.hello() == :world
  end
end
