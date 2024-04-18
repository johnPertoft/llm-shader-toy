<script lang="ts">
  import { OpenAI } from 'openai';
  import { fade } from 'svelte/transition';
  import { Ok } from 'ts-results';
  import { AssistantMessage, UserMessage, fetchLLMResponse, getInitialMessages } from './llm';
  import { shaderCompileError } from './stores';
  import spinner from '../assets/spinner.gif';
  import type { ShaderCompileError } from './render';

  const availableModels = ['gpt-4-turbo', 'gpt-3.5-turbo'];

  // TODO: Represent the chat history as a list of ChatTurns instead.
  // With a ChatTurn being a tuple of user and assistant message.
  // And keep the SystemMessage separate.
  // Affects revert, undoRevert, the argument to fetchLLMResponse, and how
  // the messages are displayed in the template.

  // TODO: Add a watch function to messages instead to make sure we update
  // the shaderSource

  // Module state.
  let openai: OpenAI | undefined;
  let llmModel: string;
  let messages = getInitialMessages();
  let revertedMessages: Array<UserMessage | AssistantMessage> = [];
  let messageInput: HTMLTextAreaElement;
  let messageSpinner: HTMLImageElement;
  export let shaderSource: string;
  export let visible: boolean;

  function onApikeyChange(event: any): void {
    const apiKey = event.target.value;
    openai = new OpenAI({ apiKey: apiKey, dangerouslyAllowBrowser: true });
  }

  function onMessageInputKeyDown(event: any): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      if (event.target.value.trim() !== '') {
        const userMessage = event.target.value.trim();
        sendUserMessage(userMessage);
      }
    }
  }

  // TODO: Is this really better than just passing this as a prop? Seems like the same thing.
  shaderCompileError.subscribe(onShaderCompileError);
  function onShaderCompileError(error: ShaderCompileError | null): void {
    if (error === null) {
      return;
    }
    if (messageInput === undefined) {
      return;
    }

    // TODO: Maybe make this less intrusive.
    // TODO: Also need to remove it if it's fixed by manual means
    const userMessageSuggestion = `
I tried to compile this shader, but it failed with the following error:
\`\`\`
${error.info}
\`\`\`
    `.trim();
    messageInput.value = userMessageSuggestion;
  }

  async function sendUserMessage(userMessage: string): Promise<void> {
    // TODO: svelte has some await directives to handle this toggling instead
    messageInput.readOnly = true;
    messageSpinner.style.visibility = 'visible';
    const llmResponse = await fetchLLMResponse(
      openai!,
      llmModel,
      messages,
      shaderSource,
      userMessage
    );
    messageInput.readOnly = false;
    messageSpinner.style.visibility = 'hidden';
    messageInput.value = '';

    llmResponse
      .mapErr((err) => {
        // TODO: Display error message somewhere.
        console.error(err);
        openai = undefined; // TODO: Only if api key is invalid.
        return err;
      })
      .andThen((llmResponse) => {
        shaderSource = llmResponse.shaderSource;
        messages = llmResponse.messages;
        revertedMessages = [];
        return Ok(Ok.EMPTY);
      });
  }

  function revert(): void {
    // The messages state looks like this:
    // [SystemMessage, UserMessage, AssistantMessage, UserMessage, AssistantMessage, ...]
    // A call to this function should remove the last AssistantMessage and UserMessage.

    // If only the SystemMessage is left, do nothing.
    if (messages.length <= 1) {
      return;
    }

    // TODO: Allow to undo the revert by pushing this to a stack somewhere.
    // Save the last two messages.
    const lastTwoMessages = messages.slice(-2);
    revertedMessages = revertedMessages.concat(lastTwoMessages);

    // Remove the last two messages.
    messages = messages.slice(0, -2);

    // TODO: Add a watch function to messages instead to make sure we update the shaderSource
    // whenever the messages change. I.e. instead of doing it here?

    if (messages.length <= 1) {
      // Just the SystemMessage left here.
      // TODO: Should save the initial shader source and revert to it here.
      return;
    }

    shaderSource = (messages[messages.length - 1] as AssistantMessage).shaderSource;
  }

  function undoRevert(): void {
    if (revertedMessages.length < 2) {
      return;
    }
    const [userMessage, assistantMessage] = revertedMessages.slice(-2);
    revertedMessages = revertedMessages.slice(0, -2);
    messages = messages.concat(userMessage, assistantMessage);
    shaderSource = (messages[messages.length - 1] as AssistantMessage).shaderSource;
  }
</script>

{#if visible}
  <div id="llm-container" transition:fade>
    {#if openai === undefined}
      <input
        type="text"
        id="llm-api-key"
        placeholder="Enter API key to start chatting"
        on:change={onApikeyChange}
      />
    {:else}
      <div id="llm-msg-history">
        {#each messages as message}
          {#if message instanceof UserMessage}
            <div class="llm-user-msg">{message.msg}</div>
          {/if}
        {/each}
      </div>

      <div id="llm-msg-input-container">
        <textarea
          id="llm-msg-input"
          bind:this={messageInput}
          placeholder="Enter message here"
          on:keydown={onMessageInputKeyDown}
        />
        <img id="llm-msg-input-spinner" bind:this={messageSpinner} src={spinner} alt="spinner" />
      </div>

      {#if messages.length >= 2}
        <button on:click={revert}>Revert</button>
      {/if}
      {#if revertedMessages.length >= 2}
        <button on:click={undoRevert}>Undo revert</button>
      {/if}

      <select bind:value={llmModel}>
        {#each availableModels as model}
          <option value={model}>{model}</option>
        {/each}
      </select>
    {/if}
  </div>
{/if}

<style>
  #llm-api-key {
    width: 100%;
    box-sizing: border-box;
  }

  #llm-msg-history {
    display: flex;
    flex-direction: column;
    width: 100%;
    background: field;
    max-height: 400px;
    min-height: 0px;
    overflow-y: scroll;
    scroll-behavior: smooth;
  }

  .llm-user-msg {
    background-color: #0074d9;
    border-radius: 1em 1em 0 1em;
    margin: 10px;
  }

  #llm-msg-input-container {
    position: relative;
  }

  #llm-msg-input {
    width: 100%;
    height: 100px;
    resize: none;
    box-sizing: border-box;
  }

  #llm-msg-input-spinner {
    position: absolute;
    width: 1em;
    height: 1em;
    bottom: 1em;
    right: 1em;
    visibility: hidden;
  }
</style>
