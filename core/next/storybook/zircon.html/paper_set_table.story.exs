defmodule Storybook.Systems.Zircon.HTML.PaperSetTable do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Zircon.HTML.paper_set_table/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Papers in the screening set, with delete action",
        attributes: %{
          items: [
            %{
              id: 1,
              doi: "10.1016/j.sleep.2021.03.012",
              title:
                "Evening smartphone use and sleep onset latency in adolescents: a longitudinal study",
              authors: "Smith, J.; de Vries, A.",
              year: "2021"
            },
            %{
              id: 2,
              doi: "10.1037/ppm0000312",
              title: "Social media use and depressive symptoms: a meta-analysis",
              authors: "Jansen, M.; Lee, K.",
              year: "2020"
            },
            %{
              id: 3,
              doi: "10.1093/joc/jqab045",
              title: "Screen time, wellbeing and the displacement hypothesis",
              authors: "Orben, A.; Przybylski, A.",
              year: "2019"
            }
          ]
        }
      },
      %Variation{id: :empty, description: "No papers", attributes: %{items: []}}
    ]
  end
end
