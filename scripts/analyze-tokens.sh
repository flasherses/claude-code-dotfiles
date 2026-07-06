#!/bin/bash
# analyze-tokens.sh — Claude Code Token Usage Analyzer (macOS/Linux)
# Usage: bash scripts/analyze-tokens.sh

SESSION_DIR="${HOME}/.claude/sessions"
TOP_N=10

echo "=== Claude Code Token Analyzer ==="
echo ""

if [ ! -d "$SESSION_DIR" ]; then
    echo "ERROR: Session directory not found: $SESSION_DIR"
    exit 1
fi

# Count sessions
session_count=$(find "$SESSION_DIR" -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
echo "Found $session_count session files"
echo ""

# Analyze recent sessions (by modification time)
echo "=== Recent Sessions ==="
find "$SESSION_DIR" -name "*.jsonl" -type f -printf '%T@ %s %p\n' 2>/dev/null |
    sort -rn |
    head -n "$TOP_N" |
    while read -r mtime size path; do
        name=$(basename "$path")
        lines=$(wc -l < "$path" | tr -d ' ')
        chars=$(wc -c < "$path" | tr -d ' ')
        est_tokens=$((chars / 4))
        size_kb=$((size / 1024))
        date_str=$(date -d "@${mtime%.*}" '+%Y-%m-%d %H:%M' 2>/dev/null || date -r "${mtime%.*}" '+%Y-%m-%d %H:%M' 2>/dev/null)
        echo "  $name | $date_str | ${size_kb}KB | $lines lines | ~${est_tokens} tokens"
    done

echo ""

# Config analysis
echo "=== Config Token Footprint ==="
CONFIG_DIR="${HOME}/.claude"

if [ -f "$CONFIG_DIR/CLAUDE.md" ]; then
    lines=$(wc -l < "$CONFIG_DIR/CLAUDE.md" | tr -d ' ')
    chars=$(wc -c < "$CONFIG_DIR/CLAUDE.md" | tr -d ' ')
    tokens=$((chars / 4))
    echo "  CLAUDE.md: $lines lines, ~$tokens tokens (loaded every session)"
fi

# Rules
if [ -d "$CONFIG_DIR/rules" ]; then
    rule_count=0
    for rule in "$CONFIG_DIR/rules"/*.md; do
        [ -f "$rule" ] || continue
        chars=$(wc -c < "$rule" | tr -d ' ')
        tokens=$((chars / 4))
        name=$(basename "$rule")
        if head -1 "$rule" | grep -q '^---'; then
            echo "  rules/$name: ~$tokens tokens [conditional]"
        else
            echo "  rules/$name: ~$tokens tokens [ALWAYS LOADED]"
        fi
        rule_count=$((rule_count + 1))
    done
    echo "  Rules count: $rule_count"
fi

# Skills L1
if [ -d "$CONFIG_DIR/skills" ]; then
    skill_count=$(find "$CONFIG_DIR/skills" -maxdepth 1 -type d | wc -l | tr -d ' ')
    skill_count=$((skill_count - 1))  # Subtract the directory itself
    echo "  Skills L1 overhead: ~$((skill_count * 100)) tokens ($skill_count skills x ~100 tokens)"
fi

echo ""

# Recommendations
echo "=== Optimization Recommendations ==="
echo ""

recs=0

if [ -f "$CONFIG_DIR/CLAUDE.md" ]; then
    lines=$(wc -l < "$CONFIG_DIR/CLAUDE.md" | tr -d ' ')
    if [ "$lines" -gt 300 ]; then
        echo "  CLAUDE.md is $lines lines. Consider splitting into rules/ with paths: frontmatter."
        recs=$((recs + 1))
    fi
fi

for rule in "$CONFIG_DIR/rules"/*.md; do
    [ -f "$rule" ] || continue
    if ! head -1 "$rule" | grep -q '^---'; then
        echo "  $(basename "$rule") missing YAML frontmatter — loaded every session."
        recs=$((recs + 1))
    fi
done

if [ -d "$CONFIG_DIR/skills" ]; then
    skill_count=$(find "$CONFIG_DIR/skills" -maxdepth 1 -type d | wc -l | tr -d ' ')
    skill_count=$((skill_count - 1))
    if [ "$skill_count" -gt 20 ]; then
        echo "  $skill_count skills — high L1 overhead. Audit unused skills."
        recs=$((recs + 1))
    fi
fi

if [ "$recs" -eq 0 ]; then
    echo "  No issues found. Configuration is well-optimized."
fi

echo ""
echo "=== Analysis Complete ==="
