# nvm — default node always on PATH, auto-switch only where an .nvmrc exists
#
# Resolves versions straight from ~/.nvm (no bash spawn on startup / cd).
# Falls back to real nvm (via bash) only for specs we can't resolve here.

set -q NVM_DIR; or set -gx NVM_DIR ~/.nvm
test -d $NVM_DIR/versions/node; or return

# spec (default, 20, v18.15.0, lts/iron, stable, ...) -> installed bin dir
function __nvm_resolve
    set -l spec (string trim -- $argv[1])
    # follow alias chain: default -> stable, lts/* -> lts/jod -> v22.x ...
    for i in (seq 10)
        test -f "$NVM_DIR/alias/$spec"; or break
        set spec (string trim < "$NVM_DIR/alias/$spec")
    end

    set -l installed (path basename $NVM_DIR/versions/node/v*)
    set -l match
    switch $spec
        case node stable
            set match $installed
        case '*'
            set -l v v(string replace -r '^v' '' -- $spec)
            set match (string match -- $v $installed; string match -- "$v.*" $installed)
    end

    if test (count $match) -eq 0
        # let nvm itself try (handles iojs, odd aliases, ...)
        set match (bash -c 'source "$NVM_DIR/nvm.sh" --no-use && nvm version "$1"' _ $spec 2>/dev/null)
        contains -- "$match" $installed; or return 1
    end

    set -l best (printf '%s\n' $match | sort -V | tail -1)
    echo $NVM_DIR/versions/node/$best/bin
end

# swap the nvm bin in PATH (in place, keeping order), or prepend if none
function __nvm_activate
    set -l bin $argv[1]
    set -l new
    set -l placed
    for p in $PATH
        if string match -q -- "$NVM_DIR/versions/node/*/bin" $p
            set -q placed[1]; and continue
            set p $bin
            set placed 1
        end
        set -a new $p
    end
    set -q placed[1]; or set new $bin $new
    set -gx PATH $new
    set -gx NVM_BIN $bin
end

# nearest .nvmrc walking up from $PWD (same lookup as nvm)
function __nvm_find_rc
    set -l dir $PWD
    while true
        test -f $dir/.nvmrc; and echo $dir/.nvmrc; and return
        test "$dir" = /; and return 1
        set dir (path dirname $dir)
    end
end

function __nvm_auto --on-variable PWD
    set -l rc (__nvm_find_rc)
    set -l spec default
    test -n "$rc"; and set spec (string match -rv '^\s*(#.*)?$' < $rc)[1]
    test -n "$spec"; or set spec default

    # unchanged since last switch → keep whatever is active (incl. manual `nvm use`)
    test "$spec" = "$__nvm_auto_spec"; and return
    set -g __nvm_auto_spec $spec

    if set -l bin (__nvm_resolve $spec)
        __nvm_activate $bin
        test -n "$rc"; and status is-interactive
        and echo (set_color brblack)"node "(path basename (path dirname $bin))" ← "(string replace $HOME '~' $rc)(set_color normal)
    else if test -n "$rc"
        echo (set_color yellow)"node '$spec' from .nvmrc is not installed — run: nvm install"(set_color normal) >&2
    end
end

__nvm_auto
