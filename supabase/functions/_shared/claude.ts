interface ClaudeMessage {
  role: 'user' | 'assistant';
  content: string;
}

interface ClaudeRequest {
  system: string;
  messages: ClaudeMessage[];
  max_tokens?: number;
  temperature?: number;
}

export async function callClaude(req: ClaudeRequest): Promise<string> {
  const apiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!apiKey) throw new Error('ANTHROPIC_API_KEY not set');

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: req.max_tokens ?? 1024,
      temperature: req.temperature ?? 0.7,
      system: req.system,
      messages: req.messages,
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Claude API error ${res.status}: ${err}`);
  }

  const data = await res.json();
  const textBlock = data.content?.find((b: any) => b.type === 'text');
  return textBlock?.text ?? '';
}

export async function callClaudeJSON<T>(req: ClaudeRequest): Promise<T> {
  const raw = await callClaude(req);
  const cleaned = raw.replace(/^```(?:json)?\s*\n?/i, '').replace(/\n?```\s*$/i, '').trim();
  return JSON.parse(cleaned) as T;
}
