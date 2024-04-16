<script lang="ts">
  import Canvas from './lib/Canvas.svelte';
  import Editor from './lib/Editor.svelte';

  // Module state.
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

  $: watchShaderSource(shaderSource);
  function watchShaderSource(shaderSource: string) {
    // Encode the shader source as a query parameter.
    const encodedShaderSource = btoa(shaderSource);
    const protocol = window.location.protocol;
    const host = window.location.host;
    const pathname = window.location.pathname;
    const url = `${protocol}//${host}${pathname}?state=${encodedShaderSource}`;
    window.history.replaceState({}, '', url);
  }

  // TODO: This only gets called once I think which is fine for our use case
  // but if we put this code inside onMount it doesn't seem to work as expected
  // and the shader source doesn't get updated.
  $: watchWindowHref(window.location.href);
  function watchWindowHref(href: string) {
    const searchParams = new URLSearchParams(window.location.search);
    const state = searchParams.get('state');
    if (state !== null) {
      shaderSource = atob(state);
    }
  }
</script>

<main>
  <Canvas {shaderSource} />
  <Editor bind:shaderSource />
</main>

<style>
  :global(body) {
    height: 100%;
    width: 100%;
  }
</style>
