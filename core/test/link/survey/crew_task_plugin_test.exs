defmodule Link.Survey.CrewTaskPluginTest do
  use Core.DataCase

  describe "studies" do
    alias Systems.Crew
    alias Core.Factories
    alias Link.Survey.CrewTaskPlugin

    test "prepare/3 returns correct url with panl_id" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: "campaign", reference_id: "campaign-1"})
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})
      public_id = Crew.Context.public_id(crew, user)

      url = "http://eyra.co/survey/1234"
      pepared_url = CrewTaskPlugin.prepare(url, crew, user)

      assert pepared_url == "#{url}?panl_id=#{public_id}"
    end

    test "prepare/3 returns correct url with panl_id and exisiting query" do
      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew, %{reference_type: "campaign", reference_id: "campaign-1"})
      _member = Factories.insert!(:crew_member, %{crew: crew, user: user})
      public_id = Crew.Context.public_id(crew, user)

      url = "http://eyra.co/survey/1234"
      query = "aap=noot"
      pepared_url = CrewTaskPlugin.prepare("#{url}?#{query}", crew, user)

      assert pepared_url == "#{url}?panl_id=#{public_id}&#{query}"
    end
  end
end
