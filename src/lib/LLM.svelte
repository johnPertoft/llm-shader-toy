<script lang="ts">
  import { OpenAI } from 'openai';
  import { fade } from 'svelte/transition';
  import { Ok } from 'ts-results';
  import { availableModels, fetchLLMResponse, ChatTurn, type Model } from './llm';
  import { shaderCompileError } from './stores';
  import spinner from '../assets/spinner.gif';
  import type { ShaderCompileError } from './render';

  // Module state.
  let openai: OpenAI | undefined;
  let modelSelection: Model;
  let turns: ChatTurn[] = [];
  let revertedTurns: ChatTurn[] = [];
  let messageInput: HTMLTextAreaElement;
  let messageSpinner: HTMLImageElement;
  export let visible: boolean;
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

  $: watchTurnsState(turns);
  function watchTurnsState(turns: ChatTurn[]): void {
    if (turns.length === 0) {
      // TODO: Should revert to the initial shader source here.
      // Or define a reset function and call that.
      return;
    }
    shaderSource = turns[turns.length - 1].shaderSource;
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
    messageInput.readOnly = true;
    messageSpinner.style.visibility = 'visible';
    const llmResponse = await fetchLLMResponse(
      openai!,
      modelSelection,
      turns,
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
        openai = undefined; // TODO: Only if api key error.
        return err;
      })
      .andThen((llmResponse) => {
        turns = llmResponse.turns;
        revertedTurns = [];
        return Ok(Ok.EMPTY);
      });
  }

  function revert(): void {
    if (turns.length === 0) {
      return;
    }
    const mostRecentTurn = turns[turns.length - 1];
    turns = turns.slice(0, -1);
    revertedTurns = [...revertedTurns, mostRecentTurn];
  }

  function undoRevert(): void {
    if (revertedTurns.length === 0) {
      return;
    }
    const mostRecentRevertedTurn = revertedTurns[revertedTurns.length - 1];
    revertedTurns = revertedTurns.slice(0, -1);
    turns = [...turns, mostRecentRevertedTurn];
  }
</script>

{#if visible}
  <div id="llm-container" transition:fade>
    {#if openai === undefined}
      <input
        type="text"
        id="llm-api-key"
        placeholder="Enter OpenAI API key to start chatting"
        on:change={onApikeyChange}
      />
    {:else}
      <div id="llm-msg-history">
        {#each turns as turn}
          <div class="llm-user-msg">{turn.userInput}</div>
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
      <button on:click={revert} disabled={turns.length < 1}>Revert</button>
      <button on:click={undoRevert} disabled={revertedTurns.length < 1}>Undo revert</button>

      <select bind:value={modelSelection}>
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
