import { writable } from 'svelte/store';
import { ShaderCompileError } from './render';

export const shaderCompileError = writable<ShaderCompileError | null>(null);
