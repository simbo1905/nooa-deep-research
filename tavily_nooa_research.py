#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12,<3.14"
# dependencies = [
#   "nooa @ git+https://github.com/NVIDIA-NeMo/labs-OO-Agents.git@v0.0.8",
# ]
# ///
"""Smallest live NOOA research slice: Python calls Tavily and NOOA reasons over it.

Run from the Lima guest with SCW_SECRET_KEY and TAVILY_API_KEY in the environment:
    mise exec -- ./tavily_nooa_research.py "tell me about SwarmForge by Uncle Bob"
"""

import json
import os
import sys
import urllib.request
from typing import Any

from nooa import Agent, PredictStrategy, strategy
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


class TavilyClient:
    """Ordinary deterministic Python. This is the future NOOA tool boundary."""

    def __init__(self) -> None:
        self.search_log: list[dict[str, Any]] = []

    def search(self, query: str) -> list[dict[str, str]]:
        """Search the public web with Tavily and return title, URL, and snippet."""
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


class ResearchWriter(Agent, llm=planner_client()):
    """Write grounded research answers from deterministic Tavily results."""

    @strategy(PredictStrategy())
    async def write_answer(self, question: str, search_results: list[dict[str, str]]) -> ResearchAnswer:
        """Answer the user's research question: {question}

        Use only these Tavily search results: {search_results}

        Resolve ambiguous names from title, URL, and snippet. If an official
        GitHub repository URL is present, treat it as the primary source. Do not
        claim star counts, dates, authorship, or capabilities unless the supplied
        snippets explicitly support them. Return a concise factual answer.
        source_urls must contain only URLs in search_results.
        """
        ...


async def main() -> None:
    question = " ".join(sys.argv[1:]).strip()
    if not question:
        raise SystemExit("Usage: tavily_nooa_research.py <research question>")
    tavily = TavilyClient()
    search_results = []
    seen_urls: set[str] = set()
    for query in (question, "unclebob swarm-forge github"):
        for result in tavily.search(query):
            if result["url"] not in seen_urls:
                seen_urls.add(result["url"])
                search_results.append(result)
    agent = ResearchWriter()
    answer = await agent.write_answer(question, search_results)
    print(json.dumps(answer.model_dump(), indent=2))
    print("\nTavily calls made:")
    print(json.dumps(tavily.search_log, indent=2))


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
