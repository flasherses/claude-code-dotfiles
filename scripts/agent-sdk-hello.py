#!/usr/bin/env python3
"""
Agent SDK — Parallel Code Review + Custom MCP Server.

Demonstrates L23-L24:
- query() API with async generator
- Parallel agent dispatch via asyncio.gather
- ResultMessage parsing (cost, duration, turns, session_id)
- Custom @tool definition
- create_sdk_mcp_server — package custom tools as in-process MCP server

Prerequisites:
    pip install claude-code-sdk

Usage:
    python scripts/agent-sdk-hello.py <project-path>
    python scripts/agent-sdk-hello.py D:/projects/my-app
"""

import asyncio
import sys
from pathlib import Path

try:
    from claude_code_sdk import query, tool, create_sdk_mcp_server
except ImportError:
    print("Install: pip install claude-code-sdk")
    sys.exit(1)


# ── Custom Tools ───────────────────────────────────────────


@tool
def count_changed_files(project_path: str) -> dict:
    """Count changed files in the git repository at project_path."""
    import subprocess
    result = subprocess.run(
        ["git", "-C", project_path, "diff", "--name-only", "HEAD"],
        capture_output=True, text=True,
    )
    files = [f for f in result.stdout.strip().split("\n") if f]
    return {
        "total": len(files),
        "files": files[:10],
        "truncated": len(files) > 10,
    }


@tool
def get_file_info(file_path: str) -> dict:
    """Get line count and size of a file. Use before reading large files."""
    p = Path(file_path)
    if not p.exists():
        return {"error": f"File not found: {file_path}"}
    lines = len(p.read_text(encoding="utf-8", errors="ignore").splitlines())
    size_kb = round(p.stat().st_size / 1024, 1)
    return {"path": file_path, "lines": lines, "size_kb": size_kb}


# ── Custom MCP Server ──────────────────────────────────────


def create_custom_mcp_server():
    """Package custom tools as an in-process MCP server (L24).

    Unlike external MCP servers that need npx/uvx, in-process servers
    run directly in the Claude Code process — no network, no subprocess.

    Usage in ClaudeCodeOptions:
        options = {
            "mcp_servers": {
                "my-tools": create_custom_mcp_server()
            }
        }
    """
    return create_sdk_mcp_server(
        name="my-tools",
        version="1.0.0",
        tools=[count_changed_files, get_file_info],
    )


# ── Agent Dispatch ──────────────────────────────────────────


async def run_code_review(project_path: str) -> dict:
    """Run code-reviewer agent."""
    messages = []
    async for msg in query(
        prompt=(
            f"Review recent changes in {project_path}. "
            "Focus on bugs, security issues, code quality. Be concise."
        ),
        options={
            "allowed_tools": ["Read", "Grep", "Glob"],
            "system_prompt": (
                "You are a senior code reviewer. "
                "Report only Critical and Warning issues. Be concise."
            ),
            "cwd": project_path,
            "max_turns": 5,
            "mcp_servers": {
                "my-tools": create_custom_mcp_server()
            },
        },
    ):
        messages.append(msg)

    result_msg = [m for m in messages if hasattr(m, 'type') and m.type == "result"]
    if result_msg:
        r = result_msg[0]
        return {
            "agent": "code-reviewer",
            "cost": getattr(r, "cost", 0),
            "duration_ms": getattr(r, "duration_ms", 0),
            "turns": getattr(r, "turns", 0),
            "status": "completed",
        }
    return {"agent": "code-reviewer", "status": "no_result"}


async def run_security_audit(project_path: str) -> dict:
    """Run security-auditor agent."""
    messages = []
    async for msg in query(
        prompt=(
            f"Audit recent changes in {project_path} "
            "for OWASP Top-10 vulnerabilities. Be concise."
        ),
        options={
            "allowed_tools": ["Read", "Grep", "Glob"],
            "system_prompt": (
                "You are a security auditor. "
                "Scan for OWASP Top-10 vulnerabilities. Be concise."
            ),
            "cwd": project_path,
            "max_turns": 5,
            "mcp_servers": {
                "my-tools": create_custom_mcp_server()
            },
        },
    ):
        messages.append(msg)

    result_msg = [m for m in messages if hasattr(m, 'type') and m.type == "result"]
    if result_msg:
        r = result_msg[0]
        return {
            "agent": "security-auditor",
            "cost": getattr(r, "cost", 0),
            "duration_ms": getattr(r, "duration_ms", 0),
            "turns": getattr(r, "turns", 0),
            "status": "completed",
        }
    return {"agent": "security-auditor", "status": "no_result"}


# ── Main ────────────────────────────────────────────────────


async def main():
    project_path = sys.argv[1] if len(sys.argv) > 1 else "."
    if not Path(project_path).exists():
        print(f"ERROR: Project path not found: {project_path}")
        sys.exit(1)

    print(f"=== Claude Code Agent SDK — Parallel Review + MCP Server ===")
    print(f"Project: {project_path}")
    print(f"")

    # Parallel dispatch — L08 pattern via asyncio.gather
    print("Dispatching code-reviewer + security-auditor in parallel...")
    results = await asyncio.gather(
        run_code_review(project_path),
        run_security_audit(project_path),
    )

    # Consolidate
    print("")
    print("=== Results ===")
    total_cost = 0
    for r in results:
        print(f"  {r['agent']}: {r['status']}")
        if "cost" in r and r["cost"]:
            print(f"    Cost: ${r['cost']:.4f}")
            print(f"    Duration: {r['duration_ms']}ms")
            print(f"    Turns: {r['turns']}")
            total_cost += r["cost"]

    print(f"")
    print(f"Total cost: ${total_cost:.4f}")
    print(f"MCP Server: 2 custom tools (count_changed_files, get_file_info)")
    print(f"=== Complete ===")


if __name__ == "__main__":
    asyncio.run(main())
