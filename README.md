# automations (luam edition)

A collection of automation scripts using the `luam` language.

## Structure

```
automations/
├── src/          # Source files
├── tst/          # Test suite
├── doc/          # Documentation
├── LICENSE
└── README.md
```

## Quick Start

```bash
# Run a script
luam src/repo.lua --help

# Run tests
./tst/run_all.sh
```

## Migration Notes

This project has been migrated from Lua 5.1 to the `luam` dialect.
Key changes:
- `local` keyword is removed.
- Inequality operator is `!=` (formerly `~=`).
- Multiline strings use `""" ... """` (formerly `[[ ... ]]`).
- Colon syntax for method calls (e.g., `s:gsub(...)`) is replaced with explicit function calls (e.g., `string.gsub(s, ...)`).
- Conditional statements require explicit boolean values.

## Available Commands

| Script | Description |
|--------|-------------|
| `repo.lua` | Git workflow automation (commit, sync, pre-commit) |
| `find.lua` | Search for patterns in files |
| `readdir.lua` | List directory contents |
| `edit.lua` | Open file in editor |
| `open.lua` | Open file with default program |
| `view.lua` | View delimited file as table |
| `dev.lua` | Connect to development container |
| `pkg.lua` | Distribution-agnostic package manager wrapper |

See [doc/](doc/) for detailed usage documentation.

## License

MIT License - see [LICENSE](LICENSE)
