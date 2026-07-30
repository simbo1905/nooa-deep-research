# Build ladder: from proof of life to complete deep research

Do not start a SwarmForge implementation task until rungs 1–8 work directly.
Every rung has one executable proof artifact and one stop condition.

| Rung | Build only this | Proof artifact | Stop if |
|---|---|---|---|
| 0 | Environment and provider preflights | Promptfoo D1 output; NOOA Gemma response | Python/uv, credentials, or a provider call fails |
| 1 | NOOA CodeAct + Scaleway compatibility | A NOOA agent calls one ordinary `echo_tool()` method through Mistral and returns its value | Tool-call protocol fails. Current state: **blocked**; Scaleway rejects NOOA's generated tool-call ID format |
| 2 | Deterministic Tavily adapter only | A normal Python CLI performs one Tavily search and writes sanitized JSON | Tavily response/schema is not understood |
| 3 | NOOA planner without tools | Given frozen Tavily JSON, the planner returns typed disambiguation JSON | Promptfoo assertion or typed output fails |
| 4 | First usable research command, no agent-selected tools | Python calls Tavily once, passes results to NOOA, prints a cited answer | The answer lacks the official source or includes wrong-entity facts |
| 5 | Agent-selected search tool | Replace the fixed search in rung 4 with NOOA calling `search_tavily()` itself | Rung 1 compatibility remains unresolved |
| 6 | Query expansion and disambiguation | Up to 3 parallel initial searches; select one canonical entity | Promptfoo ambiguous-name fixture fails |
| 7 | Page reading and Gemma summaries | Extract one chosen page; Gemma makes grounded notes | Summary adds claims absent from page text |
| 8 | Small deep-research loop | At most 5 subtopics, one query each, deduped page list, caps enforced | Cap, dedup, or lane-isolation tests fail |
| 9 | Report and durable artifacts | Cited Markdown report plus raw responses, extracts, plan, and summaries in one run directory | Any claim has no supporting stored source |
| 10 | Stop/start and interactive mode | Versioned JSON run-state rehydrates in a new process; optional Jupyter service uses the same contract | Resume repeats completed work or cannot restore state |
| 11 | SwarmForge development workflow | A swarm changes one later rung and its normal direct validation passes | Direct execution is not already green |

## Immediate next action: fix or bypass rung 1

The first agent-selected-tool run failed because Scaleway requires an alphanumeric
9-character tool-call ID and NOOA v0.0.8/LiteLLM emitted `_7f706029`. We must
choose one of these evidence-based routes before continuing:

1. Configure or patch the NOOA/LiteLLM adapter to generate Scaleway-valid IDs.
2. Use a provider that accepts NOOA's current CodeAct protocol for planner tool calls.
3. Temporarily implement rung 4, where deterministic Python calls Tavily first
   and NOOA only reasons over returned data. This still gives a useful direct
   research command, but is explicitly not the final agent-selected-tool design.

No persistence work, broad research loop, or SwarmForge task should begin before
we have selected and proven one route.
