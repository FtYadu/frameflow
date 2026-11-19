import { HttpError } from "./util.js";
import { query } from "./db.js";

// Cost per 1K tokens (USD), mirrors the table shipped in the iOS app.
const COST_PER_1K = {
  "claude-3-5-sonnet-20241022": 0.003,
  "claude-3-5-haiku-20241022": 0.00025,
  "claude-3-opus-20240229": 0.015,
  "gpt-4o": 0.0025,
  "gpt-4o-mini": 0.00015,
  "gpt-4-turbo": 0.01,
  "gemini-1.5-pro-latest": 0.00125,
  "gemini-1.5-flash-latest": 0.000075,
  "gemini-pro": 0.0005,
  "mistral-large-latest": 0.004,
  "mistral-medium-latest": 0.00275,
  "mistral-small-latest": 0.002,
  "llama-3.1-70b-versatile": 0.00059,
  "llama-3.1-8b-instant": 0.000059,
  "mixtral-8x7b-32768": 0.00024,
};

const ENV_KEYS = {
  anthropic: "ANTHROPIC_API_KEY",
  openai: "OPENAI_API_KEY",
  google: "GOOGLE_API_KEY",
  mistral: "MISTRAL_API_KEY",
  groq: "GROQ_API_KEY",
};

const OPENAI_COMPATIBLE = {
  openai: "https://api.openai.com/v1",
  groq: "https://api.groq.com/openai/v1",
  mistral: "https://api.mistral.ai/v1",
};

function extractText(provider, data) {
  if (provider === "anthropic") {
    return (data.content || [])
      .filter((b) => b.type === "text")
      .map((b) => b.text)
      .join("\n")
      .trim();
  }
  if (provider === "google") {
    return (
      data.candidates?.[0]?.content?.parts?.map((p) => p.text).join("") ?? ""
    ).trim();
  }
  return data.choices?.[0]?.message?.content?.trim() ?? "";
}

function extractTokens(provider, data) {
  if (provider === "anthropic")
    return (data.usage?.input_tokens ?? 0) + (data.usage?.output_tokens ?? 0);
  if (provider === "google")
    return data.usageMetadata?.totalTokenCount ?? 0;
  return data.usage?.total_tokens ?? 0;
}

async function callProvider(provider, model, apiKey, prompt, temperature, maxTokens) {
  let res;
  if (provider === "anthropic") {
    res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model,
        max_tokens: maxTokens,
        temperature,
        messages: [{ role: "user", content: prompt }],
      }),
    });
  } else if (provider === "google") {
    res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature, maxOutputTokens: maxTokens },
        }),
      }
    );
  } else {
    const base = OPENAI_COMPATIBLE[provider];
    res = await fetch(`${base}/chat/completions`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        temperature,
        max_tokens: maxTokens,
        messages: [{ role: "user", content: prompt }],
      }),
    });
  }

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg =
      data?.error?.message || data?.message || `Provider returned ${res.status}`;
    throw new HttpError(502, `${provider} error: ${msg}`);
  }
  return data;
}

/**
 * Runs a completion through the chosen provider. The user's key (stored in the
 * app keychain and sent per request) is preferred; server env keys are a
 * fallback. Usage is recorded per user.
 */
export async function runCompletion({
  userId,
  provider,
  model,
  prompt,
  temperature = 0.7,
  maxTokens = 1000,
  apiKey,
}) {
  const key = apiKey || process.env[ENV_KEYS[provider] ?? ""] || null;
  if (!key) {
    throw new HttpError(
      403,
      `No API key available for ${provider}. Add one in AI Settings.`
    );
  }

  const data = await callProvider(
    provider,
    model,
    key,
    prompt,
    temperature,
    maxTokens
  );

  const text = extractText(provider, data);
  if (!text) throw new HttpError(502, "Provider returned an empty response");

  const tokensUsed = extractTokens(provider, data);
  const cost = ((tokensUsed / 1000) * (COST_PER_1K[model] ?? 0.002)).toFixed(6);

  try {
    await query(
      "INSERT INTO ai_usage (user_id, provider, model, tokens_used, cost) VALUES ($1,$2,$3,$4,$5)",
      [userId, provider, model, tokensUsed, cost]
    );
  } catch {
    // Usage logging must not fail the request.
  }

  return {
    response: text,
    tokens_used: tokensUsed,
    cost: Number(cost),
    provider,
    model,
  };
}
