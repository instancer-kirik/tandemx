defmodule CivvyWeb.Governance.ProposalLive.FormComponent do
  use CivvyWeb, :live_component
  use Surface.Component

  alias Civvy.Governance.ProposalRegistry
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Label, TextInput, TextArea, Select}
  alias Heroicons.ArrowUpTray

  prop proposal, :map, required: true
  prop current_member, :map, required: true
  prop action, :atom, required: true
  prop return_to, :string, required: true

  @impl true
  def update(%{proposal: proposal} = assigns, socket) do
    changeset = ProposalRegistry.change_proposal(proposal)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:uploading, false)
     |> assign(:selected_co_sponsors, [])}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="max-w-2xl mx-auto">
      <Form
        for={@changeset}
        change="validate"
        submit="save"
        opts={class: "space-y-6"}
      >
        <div class="bg-white shadow-sm rounded-lg divide-y divide-gray-200">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg font-medium leading-6 text-gray-900">
              {if @action == :new, do: "New Proposal", else: "Edit Proposal"}
            </h3>

            <div class="mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
              <div class="sm:col-span-4">
                <Field name="title">
                  <Label class="block text-sm font-medium text-gray-700">Title</Label>
                  <TextInput class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" />
                </Field>
              </div>

              <div class="sm:col-span-6">
                <Field name="description">
                  <Label class="block text-sm font-medium text-gray-700">Description</Label>
                  <TextArea class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" rows="4" />
                  <p class="mt-2 text-sm text-gray-500">
                    Write a detailed description of your proposal. Markdown is supported.
                  </p>
                </Field>
              </div>

              <div class="sm:col-span-3">
                <Field name="type">
                  <Label class="block text-sm font-medium text-gray-700">Type</Label>
                  <Select class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                    <option value="resolution">Resolution</option>
                    <option value="amendment">Amendment</option>
                    <option value="declaration">Declaration</option>
                    <option value="treaty">Treaty</option>
                    <option value="sanction">Sanction</option>
                  </Select>
                </Field>
              </div>

              <div class="sm:col-span-3">
                <Field name="threshold">
                  <Label class="block text-sm font-medium text-gray-700">Voting Threshold</Label>
                  <Select class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                    <option value="simple_majority">Simple Majority</option>
                    <option value="two_thirds">Two-thirds Majority</option>
                    <option value="consensus">Consensus</option>
                  </Select>
                </Field>
              </div>

              <div class="sm:col-span-6">
                <Field name="voting_period">
                  <Label class="block text-sm font-medium text-gray-700">Voting Period</Label>
                  <div class="mt-1 grid grid-cols-2 gap-4">
                    <div>
                      <Label class="block text-xs text-gray-500">Start Date</Label>
                      <TextInput type="datetime-local"
                               name="voting_period_start"
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" />
                    </div>
                    <div>
                      <Label class="block text-xs text-gray-500">End Date</Label>
                      <TextInput type="datetime-local"
                               name="voting_period_end"
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" />
                    </div>
                  </div>
                </Field>
              </div>

              <div class="sm:col-span-6">
                <Field name="tags">
                  <Label class="block text-sm font-medium text-gray-700">Tags</Label>
                  <TextInput class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                           placeholder="Comma-separated tags" />
                  <p class="mt-2 text-sm text-gray-500">
                    Add tags to help categorize your proposal
                  </p>
                </Field>
              </div>

              <div class="sm:col-span-6">
                <Field name="attachments">
                  <Label class="block text-sm font-medium text-gray-700">Attachments</Label>
                  <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
                    <div class="space-y-1 text-center">
                      <ArrowUpTray class="mx-auto h-12 w-12 text-gray-400" />
                      <div class="flex text-sm text-gray-600">
                        <label for="file-upload"
                               class="relative cursor-pointer bg-white rounded-md font-medium text-blue-600 hover:text-blue-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-blue-500">
                          <span>Upload files</span>
                          <input id="file-upload"
                                 name="attachments[]"
                                 type="file"
                                 class="sr-only"
                                 multiple />
                        </label>
                        <p class="pl-1">or drag and drop</p>
                      </div>
                      <p class="text-xs text-gray-500">
                        PDF, DOC, DOCX up to 10MB each
                      </p>
                    </div>
                  </div>
                </Field>
              </div>
            </div>
          </div>

          <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
            <button type="button"
                    class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    phx-click="cancel"
                    phx-target={@myself}>
              Cancel
            </button>
            <button type="submit"
                    class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    disabled={not @changeset.valid?}>
              {if @action == :new, do: "Create Proposal", else: "Update Proposal"}
            </button>
          </div>
        </div>
      </Form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"proposal" => proposal_params}, socket) do
    changeset =
      socket.assigns.proposal
      |> ProposalRegistry.change_proposal(proposal_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"proposal" => proposal_params}, socket) do
    save_proposal(socket, socket.assigns.action, proposal_params)
  end

  def handle_event("cancel", _, socket) do
    {:noreply, push_navigate(socket, to: socket.assigns.return_to)}
  end

  defp save_proposal(socket, :new, proposal_params) do
    case ProposalRegistry.create_proposal(proposal_params) do
      {:ok, proposal} ->
        notify_parent({:saved, proposal})

        {:noreply,
         socket
         |> put_flash(:info, "Proposal created successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_proposal(socket, :edit, proposal_params) do
    case ProposalRegistry.update_proposal(socket.assigns.proposal.id, proposal_params) do
      {:ok, proposal} ->
        notify_parent({:saved, proposal})

        {:noreply,
         socket
         |> put_flash(:info, "Proposal updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
