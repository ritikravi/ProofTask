'use strict';

/**
 * Server-side Grok (xAI) client.
 *
 * The XAI_API_KEY is read from env and NEVER forwarded to clients.
 * All AI calls on the production path go through this module.
 */

const axios = require('axios');

const BASE_URL = 'https://api.x.ai/v1';
const MODEL = process.env.XAI_MODEL || 'grok-2-vision-1212';

function headers() {
  const key = process.env.XAI_API_KEY;
  if (!key) throw new Error('XAI_API_KEY is not set');
  return { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' };
}

/**
 * Structured call with tool/function calling.
 * Returns the parsed arguments object from the first tool call.
 *
 * @param {string} system
 * @param {string} user
 * @param {object} schema  — JSON Schema for the parameters
 * @param {Array}  images  — [{mime, base64}]
 * @param {number} temperature
 */
async function structured({ system, user, schema, images = [], temperature = 0.2 }) {
  // Build user content
  let userContent = user;
  if (images.length > 0) {
    userContent = [
      ...images.map((img) => ({
        type: 'image_url',
        image_url: { url: `data:${img.mime};base64,${img.base64}` },
      })),
      { type: 'text', text: user },
    ];
  }

  const body = {
    model: MODEL,
    temperature,
    max_tokens: 600,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: userContent },
    ],
    tools: [
      {
        type: 'function',
        function: {
          name: 'submit_verdict',
          description: 'Submit the structured result.',
          parameters: schema,
        },
      },
    ],
    tool_choice: { type: 'function', function: { name: 'submit_verdict' } },
  };

  const res = await axios.post(`${BASE_URL}/chat/completions`, body, {
    headers: headers(),
    timeout: 60_000,
  });

  const toolCalls = res.data?.choices?.[0]?.message?.tool_calls;
  const args = toolCalls?.[0]?.function?.arguments;
  if (!args) throw new Error('No tool_call in Grok response');

  return typeof args === 'string' ? JSON.parse(args) : args;
}

/**
 * Free-text completion (for roast messages).
 */
async function complete({ system, user, temperature = 0.9 }) {
  const body = {
    model: MODEL,
    temperature,
    max_tokens: 200,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: user },
    ],
  };

  const res = await axios.post(`${BASE_URL}/chat/completions`, body, {
    headers: headers(),
    timeout: 30_000,
  });

  const content = res.data?.choices?.[0]?.message?.content ?? '';
  if (!content.trim()) throw new Error('Empty Grok completion');
  return content.trim();
}

module.exports = { structured, complete };
