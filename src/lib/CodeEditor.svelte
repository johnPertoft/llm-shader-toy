<script lang="ts">
  import { fade } from 'svelte/transition';
  import { AceEditor } from 'svelte-ace';
  import 'brace/mode/glsl';
  import 'brace/theme/pastel_on_dark';

  // Module state.
  export let shaderSource: string;
  export let visible: boolean;
</script>

{#if visible}
  <div transition:fade>
    <AceEditor
      width="100%"
      height="400px"
      lang="glsl"
      theme="pastel_on_dark"
      bind:value={shaderSource}
    />
  </div>
{/if}
