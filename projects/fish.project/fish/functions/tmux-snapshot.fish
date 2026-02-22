function tmux-snapshot --description "Dump current tmux layout to ~/.tmux-snapshot"
    if not set -q TMUX
        echo "Not inside a tmux session"
        return 1
    end

    set -l outfile ~/.tmux-snapshot
    set -l timestamp (date "+%Y-%m-%d %H:%M:%S")

    echo "# tmux snapshot — $timestamp" > $outfile
    echo "# Restore manually or use as reference if resurrect fails" >> $outfile
    echo "" >> $outfile

    for sess in (tmux list-sessions -F '#{session_name}')
        echo "## Session: $sess" >> $outfile
        echo "" >> $outfile

        for win in (tmux list-windows -t "$sess" -F '#{window_index}:#{window_name}:#{window_layout}:#{window_active}')
            set -l idx (string split ':' $win)[1]
            set -l name (string split ':' $win)[2]
            set -l layout (string split ':' $win)[3]
            set -l active (string split ':' $win)[4]

            set -l marker ""
            test "$active" = "1" && set marker " (active)"

            echo "### Window $idx: $name$marker" >> $outfile
            echo "    layout: $layout" >> $outfile

            for pane in (tmux list-panes -t "$sess:$idx" -F '#{pane_index}|#{pane_current_path}|#{pane_current_command}|#{pane_active}|#{pane_width}x#{pane_height}')
                set -l parts (string split '|' $pane)
                set -l pi $parts[1]
                set -l pdir $parts[2]
                set -l pcmd $parts[3]
                set -l pact $parts[4]
                set -l psize $parts[5]

                set -l pmarker ""
                test "$pact" = "1" && set pmarker " (active)"

                echo "    pane $pi:$pmarker $psize cmd=$pcmd dir=$pdir" >> $outfile
            end
            echo "" >> $outfile
        end
    end

    echo "Snapshot saved to $outfile"
end
