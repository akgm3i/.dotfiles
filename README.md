# akgm dotfiles

[![Last Commit](https://img.shields.io/github/last-commit/akgm3i/.dotfiles)](https://github.com/akgm3i/.dotfiles/commits/master)


## About

### OS

Ubuntu (WSL) / macOS

### Tools

- Git: Git related global settings
- iTerm2: macOS用のターミナル
- Sheldon: シェルプラグインマネージャー
- Tmux: ターミナルマルチプレクサ
- Zsh: shell
- Bash: shell

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/akgm3i/.dotfiles/master/install.sh | bash
```

### インストール内容

`install.sh` は以下の処理を順に実行する。

1.  依存関係のチェックとインストール:
    *   [Tools](#tools) がインストールされているかを確認する。
    *   不足している場合は、OSに応じて `apt` (Debian/Ubuntu) または `brew` (macOS) を使用して自動的にインストールを行う。
    *   パスワードの入力が求められることがある。
    *   macOSの場合、Homebrewがインストールされていない場合はこれも自動でインストールする。

2.  .dotfilesのクローン / 更新:
    *   `DOTPATH` で指定された場所にdotfilesリポジトリが存在しない場合、 [.dotfiles](https://github.com/akgm3i/.dotfiles) をクローンする。
    *   既に存在する場合は、最新の状態に更新 (`git pull`) する。

3.  シンボリックリンクの作成:
    *   .dotfiles内の設定ファイルやディレクトリへのシンボリックリンクを `$XDG_CONFIG_HOME` や `$HOME` 配下に作成する。
    *   既存のファイルやディレクトリがある場合、それらは `$XDG_DATA_HOME/dotfiles/backup_YYYYMMDDHHMMSS/` 以下にバックアップする。

4.  追加ツールのインストール:
    *   `mise` と `sheldon` が未導入の場合はインストールする。
    *   `mise` のグローバル設定を trust し、定義されたツールをインストールする。

5.  デフォルトシェルのZshへの変更:
    *   デフォルトシェルがZshでない場合、Zshに変更する。
    *   パスワードの入力が求められることがある。

### 環境変数

#### `DOTPATH`

.dotfilesリポジトリをクローンする場所を指定する。
デフォルトでは、`install.sh` があるディレクトリの `.dotfiles` サブディレクトリ (`$PWD/.dotfiles`) となる。

> 例: ~/src/github.com/akgm3i/.dotfiles にインストールする場合
> ```bash
> curl -fsSL https://raw.githubusercontent.com/akgm3i/.dotfiles/master/install.sh | DOTPATH="$HOME/src/github.com/akgm3i/.dotfiles" bash
> ```

## アンインストール

```bash
./uninstall.sh
```

`install.sh` を実行した際のバックアップを復元する。

## Zsh設定
### Plugins
- [romkatv/zsh-defer](https://github.com/romkatv/zsh-defer): Deferred loading of plugins in Zsh
- [sindresorhus/pure](https://github.com/sindresorhus/pure): Pretty, minimal and fast ZSH prompt
- [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions): Fish-like autosuggestions for Zsh
- [zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions): Additional completion definitions for Zsh
- [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting): Fish shell like syntax highlighting for Zsh

### Aliases
#### Common aliases (shared with Bash)
##### ls

| Alias | Command | Description |
| :--- | :--- | :--- |
| `..` | `cd ../` | Move to parent directory |
| `ls` | `eza --git --icons` | List files with eza (git & icons) |
| `ld` | `eza -ld` | Show info about the directory |
| `ll` | `eza -lF` | Show long file information |
| `la` | `eza -aF` | Show hidden files |
| `lla` | `eza -laF` | Show hidden all files |
| `lx` | `eza -lXB` | Sort by extension |
| `lk` | `eza -lSr` | Sort by size, biggest last |
| `lt` | `eza -ltr` | Sort by date, most recent last |
| `lc` | `eza -ltcr` | Sort by and show change time, most recent last |
| `lu` | `eza -ltur` | Sort by and show access time, most recent last |
| `lr` | `eza -lR` | Recursive ls |

##### cat

| Alias | Command | Description |
| :--- | :--- | :--- |
| `cat` | `bat` | Display file content with bat |

## Bash設定
- `~/.config/bash/[0-9][0-9]_*.bash` を `plugins.bash.toml` で定義した `sheldon` プロファイルから読み込む。
- `shell/env.sh` に共通の環境変数をまとめており、Zsh/Bash 双方で共有。
- 共通エイリアスは `shell/aliases.sh` に定義している。

### Sheldon profiles

| Shell | Config | Loaded items |
| :--- | :--- | :--- |
| Zsh | `sheldon/plugins.toml` | `pure`, `zsh-completions`, `zsh-defer`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `~/.config/zsh/[0-9][0-9]_*.zsh` |
| Bash | `sheldon/plugins.bash.toml` | `~/.config/bash/[0-9][0-9]_*.bash` |

## Mise設定

`mise/config.toml` で以下のツールと言語ランタイムを管理する。

### Tools

| Tool | Version | Purpose |
| :--- | :--- | :--- |
| `bat` | `latest` | `cat` 代替のファイル表示 |
| `npm:@openai/codex` | `latest` | OpenAI Codex CLI |
| `eza` | `latest` | `ls` 代替のファイル一覧 |
| `fd` | `latest` | ファイル検索 |
| `fzf` | `latest` | fuzzy finder |
| `gemini` | `latest` | Gemini CLI |
| `gh` | `latest` | GitHub CLI |
| `ghq` | `latest` | repository manager |
| `jq` | `latest` | JSON processor |
| `usage` | `latest` | CLI usage helper |

### Languages

| Runtime | Version |
| :--- | :--- |
| `deno` | `2.5` |
| `go` | `1.25` |
| `node` | `22` |
| `python` | `3.13` |
| `rust` | `1.89` |


## Applications

### Git

#### config

## Env
