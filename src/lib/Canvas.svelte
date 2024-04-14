<script lang="ts">
  import { onMount } from 'svelte';
  import { Renderer, ShaderCompileError } from './render';
  import { asOption } from './utils';

  // TODO:
  // - Add a pause button
  // - Add a speed slider
  // - Figure out best practices around lifecycle and prop changes here.
  // - Support vertex manipulation too?
  // - Maybe don't trigger a rebuild on every key-press if possible.
  // - Fix resizing of the canvas via binding somehow.
  //   Also, many circle shapes seem to be ellipses, maybe something else is wrong.
  //   As well as not being "centered".
  //   Maybe see https://svelte.dev/repl/49b8091d3d5c400b8c912be90d03c93e?version=3.24.0
  // - Display some error message if we can't get a webgl2 context.
  // - Take inspiration from https://learn.svelte.dev/tutorial/update
  //   to display the llm chat
  // - For things like rendering params that should be possible to update via the ui
  //   Can we have the params object live here to have it be updated reactively
  //   and the renderer keeps a reference to it?
  //   Would mean we couln't reassign that object though.
  //   Actually, seems like stores is what we want for this.

  // Links:
  // - https://webgl-shaders.com/

  // Module state.
  let width: number;
  let height: number;
  let canvas: HTMLCanvasElement;
  let gl: WebGL2RenderingContext;
  let renderer: Renderer;
  let mounted: boolean = false; // TODO: Needed?
  export let shaderSource = '';

  onMount(() => {
    canvas.width = width;
    canvas.height = height;

    gl = asOption(canvas.getContext('webgl2')).expect('Failed to get webgl2 context');
    renderer = new Renderer(gl);
    mounted = true;
  });

  // Trigger a re-render when the shader source changes.
  $: if (mounted && shaderSource !== '') {
    try {
      renderer.run(shaderSource);
    } catch (e) {
      if (e instanceof ShaderCompileError) {
        console.error(e.message);
        console.error(e.info);
      } else {
        console.error('Unknown error');
        throw e;
      }
    }
  }
</script>

<canvas id="canvas" bind:this={canvas} bind:clientWidth={width} bind:clientHeight={height}></canvas>

<style>
  #canvas {
    display: flex;
    position: absolute;
    top: 0;
    bottom: 0;
    left: 0;
    right: 0;
    height: 100%;
    width: 100%;
  }
</style>
