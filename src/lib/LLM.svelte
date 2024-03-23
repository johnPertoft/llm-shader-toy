<script lang="ts">
  import { OpenAI } from 'openai';
  import { AssistantMessage, UserMessage, fetchLLMResponse, getInitialMessages } from './llm';
  import { Ok } from 'ts-results';

  // TODO:
  // - Save api key in local storage?
  // - Feed errors back to LLM so it can fix it automatically? Or at least display somewhere
  // - Add some kind of "save" button to save a shader, maybe belongs in Editor.svelte
  // - Add option of choosing the model to use.
  // - Add specific error for when the api key is invalid and show the api key entry field again.
  //   Plus some error message.
  // - Detect manual changes to the shader code and insert message to LLM about it?
  // - Define some function that the LLM can use to, e.g. for going back to earlier states?
  // - Maybe some more clever prompting techniques depending on what the user seems to be asking
  //   for? E.g. if they want to start from scratch or iteratively change the shader.

  // Module state.
  let openai: OpenAI;
  let apiKey: string;
  let messages = getInitialMessages();
  let messageInput: HTMLTextAreaElement;
  export let shaderSource: string;

  function onApikeyChange(event: { target: { value: string } }): void {
    apiKey = event.target.value;
    openai = new OpenAI({ apiKey: apiKey, dangerouslyAllowBrowser: true });
  }

  function onMessageInputKeyDown(event): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      if (event.target.value.trim() !== '') {
        const userMessage = event.target.value.trim();
        sendUserMessage(userMessage);
      }
    }
  }

  async function sendUserMessage(userMessage: string): Promise<void> {
    messageInput.readOnly = true;
    const llmResponse = await fetchLLMResponse(openai, messages, shaderSource, userMessage);
    messageInput.readOnly = false;
    messageInput.value = '';

    // TODO: Where to show errors from this?
    llmResponse.andThen((llmResponse) => {
      shaderSource = llmResponse.shaderSource;
      messages = llmResponse.messages;
      return Ok(Ok.EMPTY);
    });
  }

  function revertMessagesState(message_idx: number): void {
    // TODO:
    // - Should be possible to revert to before any user message too.
    // - Maybe consider some better structure for this.
    //   e.g. should avoid this being called with message_idx
    //   pointing to something that is not an AssistantMessage.
    if (!(messages[message_idx] instanceof AssistantMessage)) {
      console.error('Tried to revert to a non-assistant message');
      return;
    }
    messages = messages.slice(0, message_idx + 1);
    shaderSource = (messages[message_idx] as AssistantMessage).shaderSource;
  }
</script>

<div id="llm-container">
  {#if apiKey === undefined}
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
    <textarea
      id="llm-msg-input"
      bind:this={messageInput}
      placeholder="Enter message here"
      on:keydown={onMessageInputKeyDown}
    />
  {/if}
</div>

<style>
  #llm-api-key {
    width: 100%;
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

  #llm-msg-input {
    margin-top: 25px;
    width: 100%;
    height: 100px;
  }
</style>
