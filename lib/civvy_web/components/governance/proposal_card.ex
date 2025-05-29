defmodule CivvyWeb.Components.Governance.ProposalCard do
  use Surface.Component

  alias Heroicons.Users
  alias Heroicons.ThumbUp
  alias Heroicons.ThumbDown
  alias Heroicons.MinusCircle

  prop proposal, :map, required: true
  prop current_member, :map, required: true
  prop class, :css_class, default: ""

  def render(assigns) do
    ~F"""
    <div class={"rounded-lg border bg-white shadow-sm transition hover:shadow-md", @class}>
      <div class="p-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <div class={"px-2 py-1 text-xs font-medium rounded-full",
              "bg-blue-100 text-blue-800": @proposal.state == :draft,
              "bg-yellow-100 text-yellow-800": @proposal.state == :voting,
              "bg-green-100 text-green-800": @proposal.state == :passed,
              "bg-red-100 text-red-800": @proposal.state == :rejected,
              "bg-gray-100 text-gray-800": @proposal.state == :withdrawn
            }>
              {String.upcase(to_string(@proposal.state))}
            </div>
            <div class={"px-2 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-800"}>
              {String.upcase(to_string(@proposal.type))}
            </div>
          </div>
          <div class="text-sm text-gray-500">
            {format_date(@proposal.created_at)}
          </div>
        </div>

        <h3 class="mt-3 text-lg font-semibold text-gray-900">
          {@proposal.title}
        </h3>

        <p class="mt-2 text-sm text-gray-600 line-clamp-2">
          {@proposal.description}
        </p>

        <div class="mt-4">
          <div class="flex items-center space-x-4">
            <div class="flex items-center text-sm text-gray-500">
              <Users class="w-4 h-4 mr-1" />
              {length(@proposal.co_sponsors)} Co-sponsors
            </div>

            {#if @proposal.state == :voting}
              <div class="flex items-center space-x-2">
                <div class="flex items-center text-sm text-green-600">
                  <ThumbUp class="w-4 h-4 mr-1" />
                  {@proposal.votes.yes}
                </div>
                <div class="flex items-center text-sm text-red-600">
                  <ThumbDown class="w-4 h-4 mr-1" />
                  {@proposal.votes.no}
                </div>
                <div class="flex items-center text-sm text-gray-500">
                  <MinusCircle class="w-4 h-4 mr-1" />
                  {@proposal.votes.abstain}
                </div>
              </div>
            {/if}
          </div>
        </div>

        {#if show_voting_buttons?(@proposal, @current_member)}
          <div class="mt-4 flex items-center space-x-2">
            <button class="px-3 py-1 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700"
                    :on-click="vote"
                    phx-value-vote="yes">
              Vote Yes
            </button>
            <button class="px-3 py-1 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700"
                    :on-click="vote"
                    phx-value-vote="no">
              Vote No
            </button>
            <button class="px-3 py-1 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200"
                    :on-click="vote"
                    phx-value-vote="abstain">
              Abstain
            </button>
          </div>
        {/if}
      </div>
    </div>
    """
  end

  defp format_date(datetime) do
    Timex.format!(datetime, "{relative}", :relative)
  end

  defp show_voting_buttons?(proposal, current_member) do
    proposal.state == :voting and
    not Map.has_key?(proposal.voting_record, current_member.id)
  end
end
