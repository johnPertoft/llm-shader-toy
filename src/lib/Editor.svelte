<script lang="ts">
  import CodeEditor from './CodeEditor.svelte';
  import LLM from './LLM.svelte';

  // TODO:
  // - Make the editor container collapsible to the left
  // - Add a reset button
  // - Move the revert logic here instead?
  //   Needs to be matched with the messages though

  // Module state.
  export let shaderSource: string;
</script>

<div id="editor-container">
  <CodeEditor bind:shaderSource />
  <LLM bind:shaderSource />
</div>

<style>
  #editor-container {
    display: block;
    position: absolute;
    top: 0;
    left: 0;
    width: 25%;
    min-width: 300pt;
    z-index: 999;
    background-color: rgba(0, 0, 0, 0.5);
  }
</style>
