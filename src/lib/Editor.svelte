<script lang="ts">
  import CodeEditor from './CodeEditor.svelte';
  import LLM from './LLM.svelte';

  // Module state.
  export let shaderSource: string;
  let visible = true;
</script>

<div id="editor-container">
  <CodeEditor bind:shaderSource {visible} />
  <LLM bind:shaderSource {visible} />
</div>
<button id="hide-ui-button" on:click={() => (visible = !visible)}>
  {visible ? 'Hide' : 'Show'} UI
</button>

<style>
  #editor-container {
    display: block;
    position: absolute;
    top: 0;
    left: 0;
    width: 25%;
    min-width: 300pt;
    z-index: 1;
    background-color: rgba(0, 0, 0, 0.5);
  }

  #hide-ui-button {
    position: absolute;
    bottom: 0;
    left: 0;
    z-index: 2;
    color: white;
  }
</style>
