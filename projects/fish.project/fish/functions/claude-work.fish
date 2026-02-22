function claude-work
    set -lx CLAUDE_CONFIG_DIR $HOME/.claude-work
    claude $argv
end
