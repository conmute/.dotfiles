function claude-work
    echo $ANTHROPIC_API_KEY
    set -lx CLAUDE_CONFIG_DIR $HOME/.claude-work
    claude $argv
end
