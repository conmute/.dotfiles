function nvm
    if not type -q bass
        echo 'Bass is not installed please install it running fisher edc/bass'
        return
    end

    if not test -f .nvmrc
        echo ".nvmrc file not found in current directory"
        return
    else
        echo "Found .nvmrc file in current directory"
    end

    set -q NVM_DIR; or set -gx NVM_DIR ~/.nvm
    set -q nvm_prefix; or set -gx nvm_prefix $NVM_DIR

    bass source $nvm_prefix/nvm.sh --no-use ';' nvm $argv

    set bstatus $status

    if test $bstatus -gt 0
        return $bstatus
    end

    if test (count $argv) -lt 1
        return 0
    end

    if test $argv[1] = use; or test $argv[1] = install
        set -gx NVM_HAS_RUN 1
    end
end
