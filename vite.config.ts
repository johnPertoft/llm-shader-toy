import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

// https://vitejs.dev/config/
export default defineConfig({
  base: '/llm-shader-toy/', // Needed to serve from subfolder in GitHub Pages.
  plugins: [svelte()]
});
