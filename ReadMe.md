# akgm dotfiles

## About

### Depends

- Git: Git related global settings
- iTerm2: macOS用のターミナル
- Sheldon: シェルプラグインマネージャー
- Tmux: ターミナルマルチプレクサ
- Zsh: shell

## インストール

```bash
make install
```

### インストール内容

`make install` は以下の処理を順に実行する。

1.  依存関係のチェックとインストール:
    *   `git` や `zsh` などの依存しているアプリケーションがインストールされているかを確認する。
    *   不足している場合は、OSに応じて `apt` (Linux) または `brew` (macOS) を使用して自動的にインストールを行う。
    *   パスワードの入力が求められることがある。
    *   macOSの場合、Homebrewがインストールされていない場合はこれも自動でインストールする。

2.  dotfilesリポジトリのクローンまたは更新:
    *   `DOTPATH` で指定された場所にdotfilesリポジトリが存在しない場合、 [.dotfiles](https://github.com/akgm3i/.dotfiles) をクローンする。
    *   既に存在する場合は、最新の状態に更新 (`git pull`) する。

3.  シンボリックリンクの作成:
    *   dotfiles内の設定ファイルやディレクトリへのシンボリックリンクを `$XDG_CONFIG_HOME` や `$HOME` 配下に作成する。
    *   既存のファイルやディレクトリがある場合、それらは `$XDG_DATA_HOME/dotfiles/backup_YYYYMMDDHHMMSS/` 以下にバックアップする。

4.  デフォルトシェルのZshへの変更:
    *   デフォルトシェルがZshでない場合、Zshに変更します。
    *   パスワードの入力が求められることがある。
    *   Zshのパスが `/etc/shells` に登録されていない場合は、自動的に追加を試みます。

### 環境変数

#### `DOTPATH`

.dotfilesが配置される場所を示す。

デフォルト値: `install.sh` 実行ディレクトリが `.dotfiles` であれば、そのディレクトリ (`$(CURDIR)`) 。そうでなければ実行ディレクトリ直下の `.dotfiles` (`$(CURDIR)/.dotfiles`)

## アンインストール

```bash
./uninstall.sh
```

`install.sh` を実行した際のバックアップを復元する。

## Applications

### Git

#### config

## Env
