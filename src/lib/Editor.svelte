<script lang="ts">
  import { AceEditor } from 'svelte-ace';
  import 'brace/mode/glsl';
  import 'brace/theme/pastel_on_dark';

  // Module state.
  export let shaderSource: string;
</script>

<AceEditor
  width="100%"
  height="400px"
  lang="glsl"
  theme="pastel_on_dark"
  bind:value={shaderSource}
/>
