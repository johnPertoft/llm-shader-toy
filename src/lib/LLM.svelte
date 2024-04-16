<script lang="ts">
  import { OpenAI } from 'openai';
  import { Ok } from 'ts-results';
  import { AssistantMessage, UserMessage, fetchLLMResponse, getInitialMessages } from './llm';
  import { shaderCompileError } from './stores';
  import spinner from '../assets/spinner.gif';
  import type { ShaderCompileError } from './render';

  const availableModels = ['gpt-4-turbo', 'gpt-3.5-turbo'];

  // Module state.
  let openai: OpenAI | undefined;
  let llmModel: string;
  let messages = getInitialMessages();
  let messageInput: HTMLTextAreaElement;
  let messageSpinner: HTMLImageElement;
  export let shaderSource: string;

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
    if (error === null) return;
    console.log('HERE');
    console.log(error);
    // TODO: Feed the error message to the LLM model.
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
        openai = undefined;
        return err;
      })
      .andThen((llmResponse) => {
        shaderSource = llmResponse.shaderSource;
        messages = llmResponse.messages;
        return Ok(Ok.EMPTY);
      });
  }

  function revertMessagesState(message_idx: number): void {
    if (!(messages[message_idx] instanceof AssistantMessage)) {
      console.error('Tried to revert to a non-assistant message');
      return;
    }
    messages = messages.slice(0, message_idx + 1);
    shaderSource = (messages[message_idx] as AssistantMessage).shaderSource;
  }
</script>

<div id="llm-container">
  {#if openai === undefined}
    <input
      type="text"
      id="llm-api-key"
      placeholder="Enter API key to start chatting"
      on:change={onApikeyChange}
    />
  {:else}
    <div id="llm-msg-history">
      {#each messages.entries() as [message_idx, message]}
        {#if message instanceof UserMessage}
          <div class="llm-user-msg">{message.msg}</div>
        {:else if message instanceof AssistantMessage}
          <div class="llm-assistant-msg">
            <button on:click={() => revertMessagesState(message_idx)}>Revert to this shader</button>
          </div>
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

    <select bind:value={llmModel}>
      {#each availableModels as model}
        <option value={model}>{model}</option>
      {/each}
    </select>
  {/if}
</div>

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

  .llm-assistant-msg {
    background-color: #6b6c6d;
    border-radius: 1em 1em 1em 0;
    margin: 10px;
  }

  .llm-assistant-msg button {
    border-radius: 1em 1em 1em 1em;
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
