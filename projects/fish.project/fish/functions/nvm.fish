function nvm -d "Node version manager (bash nvm via bass)"
    if not type -q bass
        echo 'Bass is not installed please install it running fisher install edc/bass'
        return 1
    end

    set -q NVM_DIR; or set -gx NVM_DIR ~/.nvm
    bass source $NVM_DIR/nvm.sh --no-use ';' nvm $argv
end
