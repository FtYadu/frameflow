import { Router } from "express";
import { HttpError, requireString, optionalString } from "../util.js";
import { authRequired } from "../auth.js";
import { runCompletion } from "../aiGateway.js";
import { rateLimit } from "../util.js";

const router = Router();
router.use(authRequired);

const PROVIDERS = ["anthropic", "openai", "google", "mistral", "groq"];

router.post(
  "/generate",
  rateLimit({ windowMs: 60_000, max: 20 }),
  async (req, res, next) => {
    try {
      const prompt = requireString(req.body, "prompt", { max: 20_000 });
      const provider = req.body?.provider ?? "anthropic";
      if (!PROVIDERS.includes(provider)) {
        throw new HttpError(
          400,
          `Field 'provider' must be one of: ${PROVIDERS.join(", ")}`
        );
      }
      const model =
        optionalString(req.body, "model", { max: 100 }) ||
        (provider === "anthropic"
          ? "claude-3-5-haiku-20241022"
          : provider === "openai"
            ? "gpt-4o-mini"
            : provider === "google"
              ? "gemini-1.5-flash-latest"
              : provider === "groq"
                ? "llama-3.1-8b-instant"
                : "mistral-small-latest");

      const temperature = Math.min(
        Math.max(Number(req.body?.temperature) || 0.7, 0),
        1
      );
      const maxTokens = Math.min(
        Math.max(Number(req.body?.max_tokens) || 1000, 1),
        8000
      );

      const result = await runCompletion({
        userId: req.userId,
        provider,
        model,
        prompt,
        temperature,
        maxTokens,
        apiKey: optionalString(req.body, "api_key", { max: 500 }),
      });

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
);

export default router;
