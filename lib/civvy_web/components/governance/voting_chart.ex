defmodule CivvyWeb.Components.Governance.VotingChart do
  use Surface.Component

  alias CivvyWeb.Components.Governance.VotingChart # Self alias for clarity, optional
  alias Contex.CategoryChart
  alias Contex.Dataset
  alias Contex.Scale.Band
  alias Contex.Scale.Linear

  # Prop for the voting statistics
  prop stats, :map, required: true

  def render(assigns) do
    ~F"""
    <div class="w-full">
      {#if @stats && @stats.total_votes > 0}
        <CategoryChart width={300} height={200}>
          <Dataset
            data={transform_stats_for_chart(@stats)}
            label_accessor={&(&1.label)}
            value_accessor={&(&1.value)}
          >
            <Band field={:label} nice={true} padding_inner={0.1} padding_outer={0.1} />
            <Linear field={:value} nice={true} domain_min={0} />
          </Dataset>
        </CategoryChart>
        <div class="mt-2 text-xs text-gray-500 text-center">
          Total Votes: {@stats.total_votes}
        </div>
      {#else}
        <div class="flex items-center justify-center h-48 bg-gray-50 rounded-md">
          <p class="text-gray-500">No voting data available yet.</p>
        </div>
      {/if}
    </div>
    """
  end

  defp transform_stats_for_chart(stats) do
    [
      %{label: "Yes", value: stats.yes_percentage},
      %{label: "No", value: stats.no_percentage},
      %{label: "Abstain", value: stats.abstain_percentage}
    ]
    |> Enum.filter(&(&1.value >= 0)) # Ensure no negative values if percentages can be negative
  end
end
