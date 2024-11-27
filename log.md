# History log

## Wed Nov 27 13:32:49 2024

Resturcutred intp `projects/` based folder, where each folder has:

- `bind.sh` - to bind scripts, files etc to corresponding user profile files
- `install.sh` - to install dependencies
- `cleanup.sh` - to cleanup by removing things which has caused by install and bind etc...

For now the `cleanup` and `install` is not in perfect state, but with distillating the dotfiles repository in small projects it helps to have better control. Specificly handle each project as a separate case, which makes it more future proof

Also we have in `scripts/` such files:

- `cleanupprojects.sh` - to run `cleanup.sh` from each projec, if exists. We run this first...
- `installprojexts.sh` - to run `install.sh` for each project, if exists. We need this to have our dependencies. For now I rely on brew install here. Perhaps in future will rely on nix and reproducability of installed versions
- `bindprojects.sh` - to run `bind.sh` for each project, if exists. The bind soft links folders and files so they are properly working from user directory

* ✅ reproducible, for example use <https://nix.dev/> which can install proper packages to make setup reproducable

We dont need fancy setup here, it's basic and it works by leveraging folder structure and proper comands. Of course nix.dev could help with version management, which can enhance stability for reproducability. That the 2nd part, but this is a decent 1st part to it

- ✅ roptional, can be enabled on whim. Like anaconda `conda` tool works with environments

We can disable projects by moving them into archive folder, and `scripts` will not touch it. But of course if we move it into another folder, named `archive` for example we need to manually deinstall what we did in `install.sh` and run `cleanup.sh`

- ✅ sharable, maintanable and forkable, like we do on github

This simple change makes it better for sharing personal findings on the matter actually! it's not the perfect and not super customizable but for now it beats the purpose of finding out, and share with others personal findings!

- ✅ modular, like we can enable certain pieces

Projects based setup helps us to do that very easely! But on big level, it's not on enabled for nested. So this is a stage 1 only, we need this to be developed for stage 2

- ✅ optable, not everything is needed - just add some of them

Same as the above...

## Fri May 31 05:03:13 EEST 2024

Following some guide <https://www.youtube.com/watch?v=V070Zmvx9AM> it had good recomendations, but I still need to cleanup the neovim setup a bit…

## Fri May 31 02:43:58 EEST 2024

Added `lengedary.nvim` to setup, with `;k` it's so much easier to find where it's actually binded!

Found from <https://neovimcraft.com/>

Usefull article for collection: would be nice to setup later different setups like described here <https://michaeluloth.com/neovim-switch-configs/>

## Mon Mar 25 00:34:31 EET 2024

I liked neovim for workflow, touchpad/mouse-free setup and zen like focus with a lot of fidgeting 😅
The inspirer was ThePrimagen, but I liked how @devsaslife had set it up.

So here are the links I followed:

- <https://www.youtube.com/watch?v=fFHlfbKVi30>
- <https://www.youtube.com/watch?v=KKxhf50FIPI>
