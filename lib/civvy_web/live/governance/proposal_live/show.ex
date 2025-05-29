defmodule CivvyWeb.Governance.ProposalLive.Show do
  use CivvyWeb, :live_view
  use Surface.Component

  alias Civvy.Governance.{ProposalRegistry, MemberState}
  alias CivvyWeb.Components.Governance.VotingChart # Assuming this component exists and will be fixed if needed
  alias Heroicons.ChevronLeft
  alias Heroicons.ChevronRight
  alias Heroicons.Clock
  alias Heroicons.PaperClip
  alias Heroicons.ThumbUp
  alias Heroicons.ThumbDown
  alias Heroicons.MinusCircle

  data page_title, :string
  data proposal, :map
  data voting_stats, :map
  data current_member, :map

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Civvy.PubSub, "proposals")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    proposal = ProposalRegistry.get_proposal!(id)
    voting_stats = calculate_voting_stats(proposal)

    {:noreply,
     socket
     |> assign(:page_title, proposal.title)
     |> assign(:proposal, proposal)
     |> assign(:voting_stats, voting_stats)
     |> assign(:current_member, get_test_member())} # TODO: Replace with real auth
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-6">
        <nav class="sm:hidden" aria-label="Back">
          <a href={~p"/governance/proposals"}
             class="flex items-center text-sm font-medium text-gray-500 hover:text-gray-700">
            <ChevronLeft class="flex-shrink-0 -ml-1 mr-1 h-5 w-5 text-gray-400" />
            Back
          </a>
        </nav>
        <nav class="hidden sm:flex" aria-label="Breadcrumb">
          <ol role="list" class="flex items-center space-x-4">
            <li>
              <div class="flex">
                <a href={~p"/governance/proposals"}
                   class="text-sm font-medium text-gray-500 hover:text-gray-700">
                  Proposals
                </a>
              </div>
            </li>
            <li>
              <div class="flex items-center">
                <ChevronRight class="flex-shrink-0 h-5 w-5 text-gray-400" />
                <span class="ml-4 text-sm font-medium text-gray-500">
                  {@proposal.title}
                </span>
              </div>
            </li>
          </ol>
        </nav>
      </div>

      <div class="lg:grid lg:grid-cols-12 lg:gap-x-5">
        <div class="space-y-6 lg:col-span-8">
          <div class="bg-white shadow-sm rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center justify-between">
                <h1 class="text-2xl font-bold text-gray-900">
                  {@proposal.title}
                </h1>
                <div class={"px-3 py-1 text-sm font-medium rounded-full",
                  "bg-blue-100 text-blue-800": @proposal.state == :draft,
                  "bg-yellow-100 text-yellow-800": @proposal.state == :voting,
                  "bg-green-100 text-green-800": @proposal.state == :passed,
                  "bg-red-100 text-red-800": @proposal.state == :rejected,
                  "bg-gray-100 text-gray-800": @proposal.state == :withdrawn
                }>
                  {String.upcase(to_string(@proposal.state))}
                </div>
              </div>

              <div class="mt-2 flex items-center text-sm text-gray-500">
                <Clock class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
                Proposed {format_date(@proposal.created_at)} by {get_member_name(@proposal.proposing_member)}
              </div>

              <div class="mt-6 prose prose-blue max-w-none">
                {raw(Earmark.as_html!(@proposal.description))}
              </div>

              <div class="mt-6">
                <div class="flex items-center space-x-2">
                  {#for tag <- @proposal.metadata.tags}
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      {tag}
                    </span>
                  {/for}
                </div>
              </div>

              {#if @proposal.metadata.attachments != []}
                <div class="mt-6">
                  <h3 class="text-lg font-medium text-gray-900">Attachments</h3>
                  <ul role="list" class="mt-2 border border-gray-200 rounded-md divide-y divide-gray-200">
                    {#for attachment <- @proposal.metadata.attachments}
                      <li class="pl-3 pr-4 py-3 flex items-center justify-between text-sm">
                        <div class="w-0 flex-1 flex items-center">
                          <PaperClip class="flex-shrink-0 h-5 w-5 text-gray-400" />
                          <span class="ml-2 flex-1 w-0 truncate">
                            {attachment}
                          </span>
                        </div>
                        <div class="ml-4 flex-shrink-0">
                          <a href="#" class="font-medium text-blue-600 hover:text-blue-500">
                            Download
                          </a>
                        </div>
                      </li>
                    {/for}
                  </ul>
                </div>
              {/if}
            </div>
          </div>

          {#if @proposal.state == :voting}
            <div class="bg-white shadow-sm rounded-lg">
              <div class="px-4 py-5 sm:p-6">
                <h2 class="text-lg font-medium text-gray-900">Cast Your Vote</h2>
                <p class="mt-1 text-sm text-gray-500">
                  Voting period ends {format_date(@proposal.voting_period.end_date)}
                </p>

                <div class="mt-6 flex items-center space-x-4">
                  <button class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                          :on-click="vote"
                          phx-value-vote="yes">
                    <ThumbUp class="mr-2 h-5 w-5" />
                    Vote Yes
                  </button>
                  <button class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                          :on-click="vote"
                          phx-value-vote="no">
                    <ThumbDown class="mr-2 h-5 w-5" />
                    Vote No
                  </button>
                  <button class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                          :on-click="vote"
                          phx-value-vote="abstain">
                    <MinusCircle class="mr-2 h-5 w-5" />
                    Abstain
                  </button>
                </div>
              </div>
            </div>
          {/if}
        </div>

        <div class="mt-6 lg:mt-0 lg:col-span-4">
          <div class="space-y-6">
            <div class="bg-white shadow-sm rounded-lg">
              <div class="px-4 py-5 sm:p-6">
                <h2 class="text-lg font-medium text-gray-900">Voting Statistics</h2>
                <div class="mt-4">
                  <VotingChart stats={@voting_stats} />
                </div>
                <dl class="mt-4 grid grid-cols-1 gap-4">
                  <div class="bg-green-50 rounded-lg p-4">
                    <dt class="text-sm font-medium text-green-800">Yes Votes</dt>
                    <dd class="mt-1 text-3xl font-semibold text-green-800">
                      {@proposal.votes.yes}
                    </dd>
                  </div>
                  <div class="bg-red-50 rounded-lg p-4">
                    <dt class="text-sm font-medium text-red-800">No Votes</dt>
                    <dd class="mt-1 text-3xl font-semibold text-red-800">
                      {@proposal.votes.no}
                    </dd>
                  </div>
                  <div class="bg-gray-50 rounded-lg p-4">
                    <dt class="text-sm font-medium text-gray-800">Abstentions</dt>
                    <dd class="mt-1 text-3xl font-semibold text-gray-800">
                      {@proposal.votes.abstain}
                    </dd>
                  </div>
                </dl>
              </div>
            </div>

            <div class="bg-white shadow-sm rounded-lg">
              <div class="px-4 py-5 sm:p-6">
                <h2 class="text-lg font-medium text-gray-900">Co-Sponsors</h2>
                <ul role="list" class="mt-4 border-t border-b border-gray-200 divide-y divide-gray-200">
                  {#for member_id <- @proposal.co_sponsors}
                    <li class="py-3 flex justify-between items-center">
                      <div class="flex items-center">
                        <span class="text-sm font-medium text-gray-900">
                          {get_member_name(member_id)}
                        </span>
                      </div>
                    </li>
                  {/for}
                </ul>
              </div>
            </div>

            <div class="bg-white shadow-sm rounded-lg">
              <div class="px-4 py-5 sm:p-6">
                <h2 class="text-lg font-medium text-gray-900">Details</h2>
                <dl class="mt-4 space-y-4">
                  <div>
                    <dt class="text-sm font-medium text-gray-500">Type</dt>
                    <dd class="mt-1 text-sm text-gray-900">
                      {String.capitalize(to_string(@proposal.type))}
                    </dd>
                  </div>
                  <div>
                    <dt class="text-sm font-medium text-gray-500">Threshold</dt>
                    <dd class="mt-1 text-sm text-gray-900">
                      {format_threshold(@proposal.threshold)}
                    </dd>
                  </div>
                  {#if @proposal.state == :voting}
                    <div>
                      <dt class="text-sm font-medium text-gray-500">Voting Period</dt>
                      <dd class="mt-1 text-sm text-gray-900">
                        {format_date(@proposal.voting_period.start_date)} to {format_date(@proposal.voting_period.end_date)}
                      </dd>
                    </div>
                  {/if}
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("vote", %{"vote" => vote}, socket) do
    case ProposalRegistry.cast_vote(
      socket.assigns.proposal.id,
      socket.assigns.current_member.id,
      String.to_atom(vote)
    ) do
      {:ok, updated_proposal} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vote cast successfully")
         |> assign(:proposal, updated_proposal)
         |> assign(:voting_stats, calculate_voting_stats(updated_proposal))}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to cast vote: #{reason}")}
    end
  end

  @impl true
  def handle_info({:proposal_updated, proposal}, socket) do
    {:noreply,
     socket
     |> assign(:proposal, proposal)
     |> assign(:voting_stats, calculate_voting_stats(proposal))}
  end

  defp calculate_voting_stats(proposal) do
    total = proposal.votes.yes + proposal.votes.no + proposal.votes.abstain
    %{
      yes_percentage: if(total > 0, do: proposal.votes.yes / total * 100, else: 0),
      no_percentage: if(total > 0, do: proposal.votes.no / total * 100, else: 0),
      abstain_percentage: if(total > 0, do: proposal.votes.abstain / total * 100, else: 0),
      total_votes: total
    }
  end

  defp format_date(datetime) do
    Timex.format!(datetime, "{Mfull} {D}, {YYYY} at {h24}:{m}")
  end

  defp format_threshold(:simple_majority), do: "Simple Majority"
  defp format_threshold(:two_thirds), do: "Two-thirds Majority"
  defp format_threshold(:consensus), do: "Consensus"

  defp get_member_name(member_id) do
    case MemberState.get_member(member_id) do
      {:ok, member} -> member.name
      _ -> member_id
    end
  end

  # TODO: Replace with real auth
  defp get_test_member do
    %{
      id: "MS_TEST",
      name: "Test Member State",
      code: "TST",
      status: :active
    }
  end
end
