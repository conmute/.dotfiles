# .dotfiles

Configurations are hard and tedius, perhaps it would be better to version controll them!

## Details

Keeping in `~/.dotfiles` folder I can keep setup and configuration here to share with others.

To make it work i symlink or reference to where it belongs, instead of whitelisting files from the `~` folder.

The symlink is done over with `.scripts/bind.sh` files

## Wishes…

I hope to have configuraitons like this to be…

- reproducible, for example use <https://nix.dev/> which can install proper packages to make setup reproducable
- optional, can be enabled on whim. Like anaconda `conda` tool works with environments
- sharable, maintanable and forkable, like we do on github
- modular, like we can enable certain pieces
- optable, not everything is needed - just add some of them
- customizable, like enable overrides which are available
- avoiding unwanted abstractions…

The big dream of this `.dotfiles` to be like a store for feature where happy lumberjack can buy and be like happy working
