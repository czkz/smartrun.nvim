# SmartRun

## Suggested configuration
```lua
vim.keymap.set('n', '<F9>', function() vim.cmd('up'); require('smartrun').run() end, { desc = 'Run current file' })
```
## Usage
- Executes current file if it is executable.
- Otherwise detects meson and npm projects from LSP.
- Can be overridden with `:let f9='whoami'` or `:let b:f9='whoami'`

For simple projects `chmod +x` and add a shebang like
- `#!/usr/bin/env python`
- `/*bin/true && exec tcc -run "$0" "$@";*/`
- `//bin/true && exec ./run.sh`
- `#!/usr/bin/env -S vala --pkg=gtk4 --pkg=gstreamer-1.0`
