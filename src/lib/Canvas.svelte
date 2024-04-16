<script lang="ts">
  import { onMount } from 'svelte';
  import { Renderer, ShaderCompileError } from './render';
  import { asOption } from './utils';

  // Module state.
  let width: number;
  let height: number;
  let canvas: HTMLCanvasElement;
  let gl: WebGL2RenderingContext;
  let renderer: Renderer;
  export let shaderSource = '';

  onMount(() => {
    canvas.width = width;
    canvas.height = height;

    gl = asOption(canvas.getContext('webgl2')).expect('Failed to get webgl2 context');
    renderer = new Renderer(gl);
    safeRunShader(shaderSource);
  });

  function safeRunShader(shaderSource: string): void {
    if (!renderer) return;
    if (shaderSource === '') return;
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

  // Trigger a re-render when the shader source changes.
  $: watchShaderSource(shaderSource);
  function watchShaderSource(shaderSource: string): void {
    safeRunShader(shaderSource);
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
