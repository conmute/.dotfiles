# Cleanup Guide

## Before Cleanup - Verification Checklist

Review the documentation in this folder to ensure you've captured everything you need:

- [ ] Read `README.md` for overview
- [ ] Review `06-recommended-features.md` for features you might want to restore
- [ ] Check `07-custom-utilities.md` for custom Lua code
- [ ] Review `04-nvim-bak-2025-10.md` if you use Obsidian
- [ ] Verify all important configurations are documented

## Extract Specific Features (Optional)

If you want to preserve specific configurations before cleanup:

### Example: Extract Obsidian Integration
```bash
# Create target directories
mkdir -p nvim/lua/config
mkdir -p nvim/lua/plugins

# Copy Obsidian files
cp nvim.bak.2025.10/lua/plugins/obsidian.lua nvim/lua/plugins/
cp nvim.bak.2025.10/lua/config/workflows.lua nvim/lua/config/
```

### Example: Extract Craftzdog Utilities
```bash
# Create utilities directory
mkdir -p nvim/lua/craftzdog

# Copy utility files
cp nvim.bak/lua/craftzdog/*.lua nvim/lua/craftzdog/
```

### Example: Extract Specific Plugin Config
```bash
# Copy a specific plugin configuration
cp nvim.bak.2025.10/lua/plugins/habits.lua nvim/lua/plugins/
```

## Safe Cleanup Command

Once you've verified the documentation and extracted any needed files:

```bash
cd /Users/Roman.Koss/.ghq/github.com/conmute/.dotfiles/projects/nvim.project

# Remove backup folders
rm -rf nvim.bak nvim.bak.2 nvim.bak.2025.10
```

## Verification After Cleanup

Check what's left:
```bash
ls -lah
```

You should see:
- `nvim/` (current config)
- `nvim-backup-analysis/` (documentation)
- `bind.sh`, `cleanup.sh`, `install.sh` (scripts)

## Space Saved

After cleanup, you'll free up:
```
120K  nvim.bak
 96K  nvim.bak.2
136K  nvim.bak.2025.10
────────────────
352K  Total saved
```

## Emergency Recovery

If you accidentally delete something and need to recover:

1. Check if you have Time Machine backups
2. Check git history if the files were committed
3. The documentation in `nvim-backup-analysis/` contains most important configurations

## Archive Option (Alternative to Delete)

If you're not comfortable deleting, you can archive instead:

```bash
# Create archive directory
mkdir -p ~/Documents/nvim-archives

# Move backups to archive
mv nvim.bak* ~/Documents/nvim-archives/

# Or create a tar archive
tar czf ~/Documents/nvim-backups-$(date +%Y%m%d).tar.gz nvim.bak*
rm -rf nvim.bak*
```

## Keep This Documentation

The `nvim-backup-analysis/` folder should be kept for reference. It contains:
- Plugin comparisons
- Custom utility implementations
- Configuration examples
- Workflow systems

Consider committing this to git:
```bash
git add nvim-backup-analysis/
git commit -m "Add nvim backup analysis documentation"
```
