import { OpenAI } from 'openai';
import { Err, Ok, Result } from 'ts-results';
import { asResult } from './utils';

const systemPrompt = `
You are a skilled graphics shader programmer.

You answer the user's prompts with only valid webgl glsl code.

The user might either want you to fix or in some other way alter some provided shader code or
they might ask you to write a shader from scratch.

Every answer should be a valid glsl shader program in the following format. You may define additional
functions as needed.

\`\`\`glsl
#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

void main() {
    // Implement the shader here.
    out_color = vec4(1.0, 1.0, 1.0, 1.0);
}
\`\`\`
`;

class SystemMessage {
  readonly role = 'system';
  constructor(readonly content: string) {}
}

class AssistantMessage {
  readonly role = 'assistant';
  constructor(
    readonly content: string,
    readonly shaderSource: string
  ) {}
}

class UserMessage {
  readonly role = 'user';
  constructor(
    readonly content: string,
    readonly msg: string
  ) {}
}

type ChatMessage = SystemMessage | AssistantMessage | UserMessage;

class LLMResponse {
  constructor(
    readonly messages: ChatMessage[],
    readonly shaderSource: string
  ) {}
}

function getInitialMessages(): ChatMessage[] {
  return [new SystemMessage(systemPrompt)];
}

async function fetchLLMResponse(
  openai: OpenAI,
  messages: ChatMessage[],
  shaderSource: string,
  userMessage: string
): Promise<Result<LLMResponse, Error>> {
  const message = `
    Current shader code:
    \`\`\`glsl
    ${shaderSource}
    \`\`\`

    ${userMessage}
    `.trim();

  const prompt = messages.concat(new UserMessage(message, userMessage));
  const response = await callLLM(openai, prompt);
  const llmResponse = response.andThen(parseResponse).map((code) => makeLLMResponse(prompt, code));

  return llmResponse;
}

async function callLLM(openai: OpenAI, messages: ChatMessage[]): Promise<Result<string, Error>> {
  try {
    const response = await openai.chat.completions.create({
      messages: messages.map((m) => ({ role: m.role, content: m.content })),
      model: 'gpt-3.5-turbo'
    });
    return asResult(response.choices[0].message.content, Error('LLMResponseFailure'));
  } catch (error) {
    console.log(error);
    // TODO: Make custom error here for e.g. api key error
    return Err(Error('LLMResponseFailure'));
  }
}

function parseResponse(response: string): Result<string, Error> {
  const regex = /```glsl([\s\S]+)```/;
  let match = response.match(regex);
  if (!match) {
    return Err(Error('ParseFailure'));
  }
  return Ok(match[1].trim());
}

function makeLLMResponse(messages: ChatMessage[], shaderSource: string): LLMResponse {
  const assistantMessage = `
    Assistant generated shader code:
    \`\`\`glsl
    ${shaderSource}
    \`\`\`
    `;
  return new LLMResponse(
    messages.concat(new AssistantMessage(assistantMessage, shaderSource)),
    shaderSource
  );
}

export { AssistantMessage, UserMessage, fetchLLMResponse, getInitialMessages };
