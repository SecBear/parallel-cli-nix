# parallel-cli-nix

Nix flake for [parallel-cli](https://parallel.ai) — AI-powered web search, content extraction, and deep research from your terminal.

**Not in nixpkgs.** This flake packages the official pre-built binaries so you can use `parallel-cli` declaratively on NixOS, nix-darwin, and Home Manager without pointing to `~/.local/bin`.

## Quick Start

```bash
# Try it without installing
nix run github:SecBear/parallel-cli-nix -- search "your query" --json

# Install to your profile
nix profile install github:SecBear/parallel-cli-nix
```

> **Note:** parallel-cli requires a [Parallel API key](https://parallel.ai). Run `parallel-cli login` after installation.

## Using as a Flake Input

### flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    parallel-cli.url = "github:SecBear/parallel-cli-nix";
  };

  outputs = { nixpkgs, parallel-cli, ... }: {
    # Use with NixOS, nix-darwin, Home Manager, or devShells
  };
}
```

### NixOS / nix-darwin

```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.parallel-cli.packages.${pkgs.system}.default
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [ "parallel-cli" ];
}
```

### Home Manager

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.parallel-cli.packages.${pkgs.system}.default
  ];
}
```

### Dev Shell

```nix
{
  devShells.${system}.default = pkgs.mkShell {
    buildInputs = [
      inputs.parallel-cli.packages.${system}.default
    ];
  };
}
```

### Overlay

```nix
{
  nixpkgs.overlays = [
    inputs.parallel-cli.overlays.default
  ];

  # Then use pkgs.parallel-cli anywhere
}
```

## Platforms

| Platform | Architecture | Status |
|----------|-------------|--------|
| Linux    | x86_64      | Supported |
| Linux    | aarch64     | Supported |
| macOS    | x86_64      | Supported |
| macOS    | aarch64 (Apple Silicon) | Supported |

## What is parallel-cli?

[Parallel](https://parallel.ai) provides AI-powered web search and research APIs built for AI agents. The CLI gives you:

- **`search`** — web search with AI-powered relevance
- **`extract`** — pull clean markdown from any URL
- **`research`** — deep multi-source research on open-ended questions
- **`enrich`** — bulk data enrichment with web-sourced fields

```bash
parallel-cli search "nix flake best practices" --json --max-results 5
parallel-cli extract https://example.com
parallel-cli research "Compare Rust web frameworks in 2026"
```

## How It Works

This flake packages the upstream [PyInstaller-bundled standalone binary](https://github.com/parallel-web/parallel-web-tools) — no Python or pip required at runtime.

- Downloads platform-specific zip from GitHub Releases
- Installs the self-contained binary + `_internal/` runtime bundle
- On Linux: `autoPatchelfHook` patches the dynamic linker
- On macOS: binary links to system dylibs (`libSystem`, `libz`) as-is
- SHA256 hashes pinned per-platform from upstream `.sha256` files

### Why `unfreeRedistributable`?

The upstream repo has no license file. The source code and binaries are publicly available on GitHub, but without an explicit license we mark it conservatively. You'll need `allowUnfree` or a predicate in your Nix config.

## Updating

```bash
# Check for new versions
./scripts/update.sh

# Update to a specific version
./scripts/update.sh 0.0.15
```

The script fetches new SHA256 hashes and patches `package.nix` automatically.

## Development

```bash
git clone https://github.com/SecBear/parallel-cli-nix
cd parallel-cli-nix

# Build
NIXPKGS_ALLOW_UNFREE=1 nix build --impure

# Test
./result/bin/parallel-cli --version

# Dev shell with parallel-cli available
NIXPKGS_ALLOW_UNFREE=1 nix develop --impure
```

## Version Pinning

Pin to a specific commit for reproducibility:

```nix
inputs.parallel-cli.url = "github:SecBear/parallel-cli-nix/<commit-sha>";
```

Or use `flake.lock` (default behavior) — run `nix flake update parallel-cli` to pull the latest.

## Related

- [parallel-web-tools](https://github.com/parallel-web/parallel-web-tools) — upstream CLI and Python SDK
- [parallel.ai](https://parallel.ai) — API docs and pricing
- [codex-cli-nix](https://github.com/sadjow/codex-cli-nix) — similar pattern for OpenAI Codex
- [claude-code-nix](https://github.com/sadjow/claude-code-nix) — similar pattern for Claude Code

## License

This Nix packaging is provided as-is. The upstream parallel-cli binary has no explicit license; see the [upstream repository](https://github.com/parallel-web/parallel-web-tools) for details.
