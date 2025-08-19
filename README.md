# akgm dotfiles

[![Last Commit](https://img.shields.io/github/last-commit/akgm3i/.dotfiles)](https://github.com/akgm3i/.dotfiles/commits/main)


## About

### OS

Ubuntu (WSL) / macOS

### Tools

- Git: Git related global settings
- iTerm2: macOS用のターミナル
- Sheldon: シェルプラグインマネージャー
- Tmux: ターミナルマルチプレクサ
- Zsh: shell

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/akgm3i/.dotfiles/refs/heads/master/install.sh | bash
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

4.  デフォルトシェルのZshへの変更:
    *   デフォルトシェルがZshでない場合、Zshに変更する。
    *   パスワードの入力が求められることがある。

### 環境変数

#### `DOTPATH`

.dotfilesリポジトリをクローンする場所を指定する。
デフォルトでは、`install.sh` があるディレクトリの `.dotfiles` サブディレクトリ (`$PWD/.dotfiles`) となる。

> 例: ~/src/github.com/akgm3i/.dotfiles にインストールする場合
> ```bash
> curl -fsSL https://raw.githubusercontent.com/akgm3i/.dotfiles/main/install.sh | DOTPATH="$HOME/src/github.com/akgm3i/.dotfiles" bash
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
### Common aliases
| Alias | Command | Description |
| :--- | :--- | :--- |

### ls
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

### cat
| Alias | Command | Description |
| :--- | :--- | :--- |
| `cat` | `bat` | Display file content with bat |

## Applications

### Git

#### config

## Env
