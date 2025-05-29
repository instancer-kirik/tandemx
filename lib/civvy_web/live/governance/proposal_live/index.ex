defmodule CivvyWeb.Governance.ProposalLive.Index do
  use CivvyWeb, :live_view
  use Surface.Component

  alias Civvy.Governance.{ProposalRegistry, MemberState}
  alias CivvyWeb.Components.Governance.ProposalCard
  alias Heroicons.MagnifyingGlass
  alias Heroicons.DocumentText

  data page_title, :string
  data filter, :string
  data sort, :string
  data proposals, :list, default: []
  data current_member, :map

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Civvy.PubSub, "proposals")
    end

    {:ok,
     socket
     |> assign(:page_title, "Global Proposals")
     |> assign(:filter, "all")
     |> assign(:sort, "newest")
     |> assign(:proposals, list_proposals())
     |> assign(:current_member, get_test_member())} # TODO: Replace with real auth
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Global Proposals</h1>
        <button class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                :on-click="new_proposal">
          New Proposal
        </button>
      </div>

      <div class="mb-6 flex items-center justify-between">
        <div class="flex items-center space-x-4">
          <select class="rounded-md border-gray-300"
                  :on-change="filter">
            <option value="all" selected={@filter == "all"}>All Proposals</option>
            <option value="draft" selected={@filter == "draft"}>Drafts</option>
            <option value="voting" selected={@filter == "voting"}>Voting</option>
            <option value="passed" selected={@filter == "passed"}>Passed</option>
            <option value="rejected" selected={@filter == "rejected"}>Rejected</option>
          </select>

          <select class="rounded-md border-gray-300"
                  :on-change="sort">
            <option value="newest" selected={@sort == "newest"}>Newest First</option>
            <option value="oldest" selected={@sort == "oldest"}>Oldest First</option>
            <option value="most_votes" selected={@sort == "most_votes"}>Most Votes</option>
          </select>
        </div>

        <div class="flex items-center space-x-2">
          <input type="text"
                 placeholder="Search proposals..."
                 class="rounded-md border-gray-300"
                 :on-input="search" />
          <button class="p-2 text-gray-400 hover:text-gray-600">
            <MagnifyingGlass class="w-5 h-5" />
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {#for proposal <- @proposals}
          <ProposalCard proposal={proposal}
                       current_member={@current_member} />
        {/for}
      </div>

      {#if Enum.empty?(@proposals)}
        <div class="text-center py-12">
          <DocumentText class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-medium text-gray-900">No proposals</h3>
          <p class="mt-1 text-sm text-gray-500">
            Get started by creating a new proposal.
          </p>
          <div class="mt-6">
            <button class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                    :on-click="new_proposal">
              New Proposal
            </button>
          </div>
        </div>
      {/if}
    </div>
    """
  end

  @impl true
  def handle_event("new_proposal", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/governance/proposals/new")}
  end

  def handle_event("filter", %{"value" => filter}, socket) do
    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:proposals, list_proposals(filter: filter, sort: socket.assigns.sort))}
  end

  def handle_event("sort", %{"value" => sort}, socket) do
    {:noreply,
     socket
     |> assign(:sort, sort)
     |> assign(:proposals, list_proposals(filter: socket.assigns.filter, sort: sort))}
  end

  def handle_event("search", %{"value" => search}, socket) do
    {:noreply,
     socket
     |> assign(:proposals, list_proposals(search: search))}
  end

  def handle_event("vote", %{"proposal-id" => proposal_id, "vote" => vote}, socket) do
    case ProposalRegistry.cast_vote(proposal_id, socket.assigns.current_member.id, String.to_atom(vote)) do
      {:ok, _updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vote cast successfully")
         |> assign(:proposals, list_proposals())}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to cast vote: #{reason}")}
    end
  end

  @impl true
  def handle_info({:proposal_updated, proposal}, socket) do
    {:noreply, update(socket, :proposals, &update_proposal_in_list(&1, proposal))}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Global Proposals")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Proposal")
    |> assign(:proposal, %{})
  end

  defp list_proposals(opts \\ []) do
    # TODO: Implement actual filtering, sorting, and search
    _opts = opts # Mark as used or remove if not needed
    []
  end

  defp update_proposal_in_list(proposals, updated_proposal) do
    Enum.map(proposals, fn proposal ->
      if proposal.id == updated_proposal.id do
        updated_proposal
      else
        proposal
      end
    end)
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
