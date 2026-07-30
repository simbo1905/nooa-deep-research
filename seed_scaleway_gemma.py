#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12,<3.14"
# dependencies = ["nooa @ git+https://github.com/NVIDIA-NeMo/labs-OO-Agents.git@v0.0.8"]
# ///
"""Smallest NOOA/Scaleway integration gate; not the final research agent."""

import asyncio
import os

from nooa import Agent
from nooa.unifiedllm import get_llm_client


SCW_BASE_URL = "https://api.scaleway.ai/5647c6fe-ecc5-4277-9e5e-9ec56b1ac2c8/v1"


def scaleway_gemma_client():
    api_key = os.environ.get("SCW_SECRET_KEY")
    if not api_key:
        raise RuntimeError("SCW_SECRET_KEY is required")
    return get_llm_client(
        "openai/gemma-4-26b-a4b-it",
        api_base=SCW_BASE_URL,
        api_key=api_key,
        temperature=0.2,
        max_tokens=8192,
    )


class PageSummaryAgent(Agent, llm=scaleway_gemma_client()):
    """You create precise research notes from one retrieved page at a time."""

    async def summarize(self, source_url: str, research_focus: str, page_text: str) -> str:
        """Write 3 concise factual bullets about this page for the research focus.

        Cite the source URL in one bullet. Do not invent facts beyond page_text.
        """
        ...


async def main() -> None:
    agent = PageSummaryAgent()
    summary = await agent.summarize(
        "https://github.com/unclebob/swarm-forge",
        "What is this software project and who is it associated with?",
        "SwarmForge is an agent coordination system for agents in different git "
        "worktrees. It uses role-specific prompts, tmux sessions, and message "
        "passing. The repository is unclebob/swarm-forge.",
    )
    print(summary)


if __name__ == "__main__":
    asyncio.run(main())
