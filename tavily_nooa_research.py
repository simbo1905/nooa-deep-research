#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12,<3.14"
# dependencies = [
#   "nooa @ git+https://github.com/NVIDIA-NeMo/labs-OO-Agents.git@v0.0.8",
# ]
# ///
"""Smallest live NOOA research slice: LLM chooses and calls a real Tavily tool.

Run from the Lima guest with SCW_SECRET_KEY and TAVILY_API_KEY in the environment:
    mise exec -- ./tavily_nooa_research.py "tell me about SwarmForge by Uncle Bob"
"""

import json
import os
import sys
import urllib.request
from typing import Any

from nooa import Agent
from nooa.unifiedllm import get_llm_client
from pydantic import BaseModel, Field


SCW_BASE_URL = "https://api.scaleway.ai/5647c6fe-ecc5-4277-9e5e-9ec56b1ac2c8/v1"
MAX_INITIAL_TERM_SEARCHES = 3
MAX_RESULTS_PER_SEARCH = 5


class ResearchAnswer(BaseModel):
    answer: str = Field(description="Concise factual answer grounded in the tool results.")
    source_urls: list[str] = Field(description="URLs actually returned by the Tavily tool.")


def planner_client():
    api_key = os.environ.get("SCW_SECRET_KEY")
    if not api_key:
        raise RuntimeError("SCW_SECRET_KEY is required")
    return get_llm_client(
        "openai/mistral-medium-3.5-128b",
        api_base=SCW_BASE_URL,
        api_key=api_key,
        temperature=0.2,
        max_tokens=2048,
    )


class TavilyResearchAgent(Agent, llm=planner_client()):
    """Research with Tavily. Never invent a source or claim a tool did not return."""

    def __init__(self) -> None:
        super().__init__()
        self.search_log: list[dict[str, Any]] = []

    def search_tavily(self, query: str) -> list[dict[str, str]]:
        """Search the public web with Tavily and return title, URL, and snippet.

        Call this at most {MAX_INITIAL_TERM_SEARCHES} times for one research
        question. Prefer a precise query that resolves people and project names.
        """
        if len(self.search_log) >= MAX_INITIAL_TERM_SEARCHES:
            return []
        api_key = os.environ.get("TAVILY_API_KEY")
        if not api_key:
            raise RuntimeError("TAVILY_API_KEY is required")
        request = urllib.request.Request(
            "https://api.tavily.com/search",
            data=json.dumps(
                {
                    "api_key": api_key,
                    "query": query,
                    "search_depth": "basic",
                    "max_results": MAX_RESULTS_PER_SEARCH,
                    "include_answer": False,
                }
            ).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=30) as response:  # nosec B310: fixed HTTPS endpoint
            payload = json.load(response)
        results = [
            {"title": item.get("title", ""), "url": item["url"], "content": item.get("content", "")}
            for item in payload.get("results", [])
            if item.get("url")
        ]
        self.search_log.append({"query": query, "results": results})
        return results

    async def investigate(self, question: str) -> ResearchAnswer:
        """Answer the user's research question: {question}

        Use search_tavily at least once before answering. Resolve ambiguous names
        from the returned title, URL, and snippet. Use no more than
        {MAX_INITIAL_TERM_SEARCHES} searches. Return a concise factual answer and
        source_urls containing only URLs returned by search_tavily.
        """
        ...


async def main() -> None:
    question = " ".join(sys.argv[1:]).strip()
    if not question:
        raise SystemExit("Usage: tavily_nooa_research.py <research question>")
    agent = TavilyResearchAgent()
    answer = await agent.investigate(question)
    print(json.dumps(answer.model_dump(), indent=2))
    print("\nTavily calls made:")
    print(json.dumps(agent.search_log, indent=2))


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
