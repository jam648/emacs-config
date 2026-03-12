# ⚠️ 他環境での互換性に関する注意事項

この設定を別の環境で使用する際に発生しうる問題とその対処法をまとめています。

---

## 1. vterm のビルド失敗

| 項目 | 内容 |
|------|------|
| **症状** | `vterm` のロード時に C モジュールのコンパイルエラーが発生する |
| **原因** | `vterm` は libvterm の C ライブラリをビルドする必要があり、`cmake` と `libtool` が必要。Windows ネイティブでは動作しない |
| **対処法** | macOS: `brew install cmake libtool` / Ubuntu: `sudo apt install cmake libtool-bin` / Windows: 使用不可 (`eshell` や `shell` で代用) |

## 2. フォント (HackGen Nerd Font) 未インストール

| 項目 | 内容 |
|------|------|
| **症状** | フォントがデフォルトにフォールバックし、Nerd Icons (`doom-modeline`, `treemacs`, marginalia 等) が豆腐 (□) で表示される |
| **原因** | HackGen Nerd Font がシステムにインストールされていない |
| **対処法** | [HackGen](https://github.com/yuru7/HackGen) をインストール後、`M-x nerd-icons-install-fonts` を実行して Nerd Icons フォントもインストールする |

## 3. uv 未インストール

| 項目 | 内容 |
|------|------|
| **症状** | Python ファイルを開いても LSP (pyright) が起動しない。デバッガー (debugpy) も動作しない |
| **原因** | `init-dev.el` は `uv tool run --from pyright pyright-langserver --stdio` で LSP を起動する。`uv` が未インストールだとコマンドが見つからない |
| **対処法** | `brew install uv` (macOS) / `curl -LsSf https://astral.sh/uv/install.sh \| sh` (Linux) |

## 4. SKK 辞書関連

| 項目 | 内容 |
|------|------|
| **症状** | 日本語変換の精度が低い、または変換できない |
| **原因** | (a) yaskkserv2 が起動していない (b) ローカル大辞書が未ダウンロード (c) ユーザー辞書パス `~/.skk-jisyo` が macSKK 前提 |
| **対処法** | (a) yaskkserv2 を起動する、または `init-input.el` の `skk-server-host` を無効化 (b) `M-x skk-get` でローカル辞書をダウンロード (c) 他の SKK 実装を使う場合は `skk-jisyo` のパスを変更 |

## 5. exec-path-from-shell の重複

| 項目 | 内容 |
|------|------|
| **症状** | macOS 起動時に PATH 同期が2回実行され、起動時間が微増する |
| **原因** | `init-core.el` (macOS 用) と `init-dev.el` (Linux GUI / WSL 用) の両方で `exec-path-from-shell` を設定している。macOS では `:if` ガードにより `init-dev.el` 側は通常スキップされるが、条件次第で二重実行される可能性がある |
| **対処法** | 実害は軽微。気になる場合は `init-dev.el` の `exec-path-from-shell` セクションの `:if` 条件に `(not (my/macos-p))` を追加する |

## 6. copilot.el / copilot-chat.el / aider.el のインストール失敗

| 項目 | 内容 |
|------|------|
| **症状** | 初回起動時に `package-vc-install` でパッケージのインストールに失敗する |
| **原因** | GitHub への HTTPS 接続が必要。プロキシ環境や GitHub アクセス制限のある環境では接続に失敗する |
| **対処法** | ネットワーク接続を確認するか、手動で `git clone` してから `load-path` に追加する |

## 7. Copilot の認証

| 項目 | 内容 |
|------|------|
| **症状** | `copilot-mode` が有効だが補完が表示されない |
| **原因** | GitHub Copilot のアカウント認証が完了していない |
| **対処法** | `M-x copilot-login` を実行してブラウザで認証フローを完了する。`copilot-chat` も同一の認証を使用する |

## 8. Emacs 28 以下

| 項目 | 内容 |
|------|------|
| **症状** | Tree-sitter、Eglot (内蔵版) が利用できない |
| **原因** | `treesit` は Emacs 29+、内蔵 `eglot` は Emacs 29+ の機能 |
| **対処法** | Emacs 29 以上にアップグレードする (30+ 推奨)。Emacs 28 では外部パッケージの `eglot` を MELPA からインストールすることで LSP は利用可能 |

## 9. org-roam DB 初期化失敗

| 項目 | 内容 |
|------|------|
| **症状** | `org-roam` ロード時に SQLite 関連のエラーが表示される |
| **原因** | `org-roam` は SQLite3 が必要。未インストールまたはバージョンが古い場合に DB 作成に失敗する |
| **対処法** | `brew install sqlite3` (macOS) / `sudo apt install sqlite3` (Ubuntu) を実行後、`M-x org-roam-db-sync` で手動同期 |

## 10. GEMINI_API_KEY / GITHUB_TOKEN 未設定

| 項目 | 内容 |
|------|------|
| **症状** | `gptel` で AI チャットが動作しない。`forge` で GitHub 連携ができない |
| **原因** | `.secret.el` に API キーが設定されていない、またはファイル自体が存在しない |
| **対処法** | `~/.emacs.d/.secret.el` を作成して環境変数を設定する (README.md のインストール手順を参照) |
