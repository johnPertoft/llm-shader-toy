<script lang="ts">
  import Canvas from './lib/Canvas.svelte';
  import Editor from './lib/Editor.svelte';
  import LLM from './lib/LLM.svelte';

  let shaderSource = `
#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

void main() {
    float r = 0.5 + 0.5 * sin(u_time);
    float g = 0.5 + 0.5 * sin(u_time / 3.0);
    float b = 0.5 + 0.5 * sin(u_time / 5.0);
    out_color = vec4(r, g, b, 1.0);
}
`.trim();
</script>

<main>
  <Canvas {shaderSource} />
  <div id="llm-editor-container">
    <Editor bind:shaderSource />
    <LLM bind:shaderSource />
  </div>
</main>

<style>
  /* TODO: Why does the editor div extend outside when using 100% */
  /* :global(html) {
  		box-sizing: border-box;
	} */
  :global(body) {
    height: 100%;
    width: 100%;
  }
  #llm-editor-container {
    display: block;
    position: absolute;
    top: 0;
    right: 0;
    width: 25%;
    min-width: 300pt;
    z-index: 999;
  }
</style>
