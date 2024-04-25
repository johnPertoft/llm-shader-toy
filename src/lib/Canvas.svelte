<script lang="ts">
  import { onMount } from 'svelte';
  import { Renderer, ShaderCompileError } from './render';
  import { shaderCompileError } from './stores';
  import { asOption } from './utils';

  // Module state.
  let width: number;
  let height: number;
  let canvas: HTMLCanvasElement;
  let gl: WebGL2RenderingContext;
  let renderer: Renderer;
  let renderTimeScale: number = 1.0;
  export let shaderSource: string = '';

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
        shaderCompileError.set(e);
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

  $: watchRenderTimeScale(renderTimeScale);
  function watchRenderTimeScale(renderTimeScale: number): void {
    if (!renderer) return;
    renderer.setRenderTimeScale(renderTimeScale);
  }
</script>

<!-- TODO: Need to wrap in container for binding clientWidth -->
<canvas id="canvas" bind:this={canvas} bind:clientWidth={width} bind:clientHeight={height}></canvas>
<div id="render-time-scale-container">
  <label for="render-time-scale">Render Time Scale</label>
  <input
    id="render-time-scale"
    type="range"
    min="0.1"
    max="10.0"
    step="0.1"
    bind:value={renderTimeScale}
  />
  <span>{renderTimeScale.toFixed(1)}</span>
</div>

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

  #render-time-scale-container {
    position: absolute;
    bottom: 0;
    right: 0;
    z-index: 100;
    background-color: rgba(0, 0, 0, 0.5);
  }
</style>
