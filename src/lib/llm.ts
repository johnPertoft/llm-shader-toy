import { APIError, OpenAI } from 'openai';
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

const availableModels = ['gpt-4-turbo', 'gpt-3.5-turbo'] as const;
type Model = (typeof availableModels)[number];

class SystemMessage {
  readonly role = 'system';
  constructor(readonly content: string) {}
}

class AssistantMessage {
  readonly role = 'assistant';
  constructor(readonly content: string) {}
}

class UserMessage {
  readonly role = 'user';
  constructor(readonly content: string) {}
}

type ChatMessage = SystemMessage | AssistantMessage | UserMessage;

class ChatTurn {
  constructor(
    readonly userMessage: UserMessage,
    readonly assistantMessage: AssistantMessage,
    readonly userInput: string,
    readonly shaderSource: string
  ) {}
}

class LLMResponse {
  constructor(
    readonly turns: ChatTurn[],
    readonly shaderSource: string
  ) {}
}

class RecoverableError extends Error {}

class UnrecoverableError extends Error {}

async function fetchLLMResponse(
  openai: OpenAI,
  model: Model,
  turns: ChatTurn[],
  currentShaderCode: string,
  userInput: string
): Promise<Result<LLMResponse, Error>> {
  const newUserMessage = makeUserMessage(userInput, currentShaderCode);
  const llmPrompt = makeLLMPrompt(turns, newUserMessage);
  const response = await callLLM(openai, model, llmPrompt);
  const llmResponse = response.andThen(parseResponse).map((newShaderCode) => {
    const newAssistantMessage = makeAssistantMessage(newShaderCode);
    const newChatTurn = new ChatTurn(newUserMessage, newAssistantMessage, userInput, newShaderCode);
    return new LLMResponse(turns.concat(newChatTurn), newShaderCode);
  });
  return llmResponse;
}

function makeUserMessage(userInput: string, code: string): UserMessage {
  const content = `
Current shader code:
\`\`\`glsl
${code}
\`\`\`

${userInput}
  `.trim();
  return new UserMessage(content);
}

function makeAssistantMessage(code: string): AssistantMessage {
  const content = `
Assistant generated shader code:
\`\`\`glsl
${code}
\`\`\`
  `.trim();
  return new AssistantMessage(content);
}

function makeLLMPrompt(turns: ChatTurn[], userMessage: UserMessage): ChatMessage[] {
  return [
    new SystemMessage(systemPrompt),
    ...turns.flatMap((turn) => [turn.userMessage, turn.assistantMessage]),
    userMessage
  ];
}

async function callLLM(
  openai: OpenAI,
  model: Model,
  prompt: Array<ChatMessage>
): Promise<Result<string, Error>> {
  try {
    const response = await openai.chat.completions.create({
      messages: prompt,
      model: model
    });
    return asResult(response.choices[0].message.content, Error('LLMResponseFailure'));
  } catch (error: unknown) {
    if (error instanceof APIError) {
      // https://platform.openai.com/docs/guides/error-codes/api-errors
      if (error.status === 401) {
        return Err(new UnrecoverableError('API key is invalid'));
      }
      if (error.status === 403) {
        return Err(new UnrecoverableError('Region not supported'));
      }
      if (error.status === 429) {
        return Err(new RecoverableError('Rate limit exceeded, try again later'));
      }
      if (error.status === 500 || error.status === 503) {
        return Err(new RecoverableError('Internal server error, try again later'));
      }
      return Err(new UnrecoverableError(`API error: ${error.message}`));
    }
    return Err(new UnrecoverableError(`Unknown Error: ${error}`));
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

export { availableModels, fetchLLMResponse, ChatTurn, RecoverableError, UnrecoverableError };
export type { Model };
