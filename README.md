# Modular Emacs Config

堅牢さ・速度・連携性を重視した、モジュール分割型の Emacs 設定ファイル群。

macOS / WSL (Windows Subsystem for Linux) / Linux に対応し、環境を自動判別して最適な設定を適用する。

## 対応環境

| 環境 | サポート状況 |
|------|-------------|
| macOS (GUI) | ✅ メイン開発環境 |
| WSL2 (GUI/TUI) | ✅ クリップボード・ブラウザ連携あり |
| Linux (GUI) | ✅ |
| Linux (TUI) | ⚠️ 一部UIが制限される |
| Windows (native) | ❌ 未対応 |

## 必須要件

- **Emacs 29 以上** (30+ 推奨、Tree-sitter / Eglot 内蔵)
- **フォント**: [HackGen Nerd Font](https://github.com/yuru7/HackGen) (未インストール時はデフォルトフォントにフォールバック)
- **外部ツール** (必須):

| ツール | 用途 | インストール例 (macOS) |
|--------|------|----------------------|
| git | バージョン管理 | `brew install git` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) | 高速検索 | `brew install ripgrep` |
| [fd](https://github.com/sharkdp/fd) | 高速ファイル検索 | `brew install fd` |
| [uv](https://github.com/astral-sh/uv) | Python パッケージ管理 | `brew install uv` |

- **外部ツール** (オプション):

| ツール | 用途 |
|--------|------|
| Node.js | TypeScript LSP |
| rust-analyzer | Rust LSP |
| pandoc | Org → Word/PDF エクスポート |
| [yaskkserv2](https://github.com/poad/yaskkserv2) | SKK 辞書サーバー |

## インストール

```bash
# 既存の設定をバックアップ
mv ~/.emacs.d ~/.emacs.d.bak

# リポジトリをクローン
git clone https://github.com/<your-username>/emacs.d.git ~/.emacs.d

# 秘匿情報ファイルを作成
cat > ~/.emacs.d/.secret.el << 'EOF'
;; -*- lexical-binding: t -*-
;; API キー等の秘匿情報
(setenv "GEMINI_API_KEY" "YOUR_API_KEY_HERE")
(setenv "GITHUB_TOKEN" "YOUR_GITHUB_TOKEN_HERE")
EOF

# Emacs を起動 (初回はパッケージの自動インストールが行われる)
emacs
```

> [!NOTE]
> 初回起動時はパッケージのダウンロード・コンパイルに数分かかります。
> Tree-sitter のグラマーは `M-x my/treesit-install-all-languages` で一括インストールできます。

## 設定の構造

```
~/.emacs.d/
├── init.el              # エントリポイント (モジュールローダー)
├── .secret.el           # 秘匿情報 (gitignore対象)
├── custom.el            # M-x customize の保存先 (gitignore対象)
├── .gitignore
└── lisp/
    ├── init-core.el       # パッケージ管理, 環境判別, フォント, 基本設定
    ├── init-ui.el         # テーマ, エフェクト, モードライン, Dashboard
    ├── init-completion.el # 補完 (Vertico, Consult, Corfu)
    ├── init-edit.el       # 編集支援 (Smartparens, YASnippet, Avy, ...)
    ├── init-input.el      # 日本語入力 (DDSKK)
    ├── init-notes.el      # Org-mode, Denote, Org-roam, Markdown
    ├── init-dev.el        # LSP, Git, Terminal, デバッガー, ヘルスチェック
    ├── init-ai.el         # AI連携 (gptel/Gemini, Aider, Copilot)
    └── init-debug.el      # デバッグ・プロファイリングツール
```

各モジュールは `condition-case` で保護されており、1つのモジュールが失敗しても他のモジュールのロードは継続する。致命的なエラー時は **Emergency モード** で最小限の設定のみ適用して起動する。

## モジュール詳細

### init-core.el — 基盤設定

| 機能 | 説明 |
|------|------|
| パッケージ管理 | MELPA / NonGNU ELPA + `use-package` |
| 環境判別 | `my/macos-p`, `my/wsl-p` で自動判別 |
| macOS 統合 | Option→Meta, Command→Super, `exec-path-from-shell` |
| WSL 統合 | クリップボード (win32yank), ブラウザ (wslview), PowerShell 連携 |
| フォント | HackGen Nerd Font (自動検出、daemon モード対応) |
| 文字コード | UTF-8、日本語環境 |
| バックアップ | `var/backup/`, `var/auto-save/` に集約 |

### init-ui.el — ビジュアル

| パッケージ | 説明 |
|-----------|------|
| modus-themes | ダーク/ライトテーマ (`<F5>` でトグル) |
| pulsar | カーソルジャンプ時の行ハイライト |
| beacon | スクロール後のカーソル位置フラッシュ |
| dimmer | 非アクティブウィンドウを薄暗く表示 |
| goggles | 編集操作の視覚フィードバック |
| anzu | 検索ヒット数の表示 |
| rainbow-delimiters | 括弧の色分け |
| nyan-mode | モードラインのNyancat進捗バー |
| doom-modeline | リッチなモードライン |
| dashboard | 起動画面 (最近のファイル, ブックマーク, プロジェクト) |
| zone | スクリーンセーバー (10分アイドル) |

### init-completion.el — 補完フレームワーク

| パッケージ | 説明 | キーバインド |
|-----------|------|-------------|
| vertico | ミニバッファ補完UI | — |
| orderless | あいまいマッチング | — |
| marginalia | 補完候補の注釈表示 | — |
| consult | 検索・ナビゲーション | `C-s` (行検索), `C-x b` (バッファ), `M-s r` (ripgrep) |
| embark | コンテキストアクション | `C-.` (act), `C-;` (dwim) |
| corfu | インライン補完 | 自動表示 |
| cape | 補完ソース拡張 | — |

### init-edit.el — 編集支援

| パッケージ | 説明 | キーバインド |
|-----------|------|-------------|
| smartparens | 括弧の自動補完 | — |
| yasnippet | スニペット展開 | — |
| apheleia | 自動フォーマット | 保存時自動実行 |
| expand-region | 選択範囲の拡張 | `C-=` |
| avy | 画面内ジャンプ | `C-:` (2文字), `M-g l` (行) |
| multiple-cursors | マルチカーソル | `C->` / `C-<` / `C-S-c C-S-c` |
| vundo | undo ツリー表示 | `C-x u` |
| drag-stuff | 行の上下移動 | `M-↑` / `M-↓` |

### init-input.el — 日本語入力

DDSKK による日本語入力環境。`C-x C-j` で SKK モードを起動。

- **辞書**: `~/.skk-jisyo` (macSKK と共有可能)
- **サーバー**: yaskkserv2 (127.0.0.1:1178) + Google変換
- **フォールバック**: ローカル大辞書 (`skk-get-jisyo/SKK-JISYO.L`)
- **daemon 対応**: フレーム作成時に GUI/TUI を自動判別して表示モードを切替

### init-notes.el — ノート・執筆

| パッケージ | 説明 | キーバインド |
|-----------|------|-------------|
| org-mode | アウトライナー・タスク管理 | — |
| org-modern | Org の見た目を改善 | — |
| denote | ファイル名ベースのノート管理 | `C-c n n` (新規), `C-c n f` (開く) |
| org-roam | DBベースの知識グラフ | `C-c r f` (検索), `C-c r i` (リンク挿入) |
| org-pomodoro | ポモドーロタイマー | `C-c C-p` (org-mode内) |
| writeroom-mode | 集中執筆モード | `M-z` |
| olivetti | 中央寄せ表示 | `C-c o` |
| ox-pandoc | Pandoc エクスポート | `C-c C-e` (Org export) |
| markdown-mode | Markdown 編集 | — |

### init-dev.el — 開発環境

| パッケージ / 機能 | 説明 | キーバインド |
|------------------|------|-------------|
| tree-sitter | 構文解析 (Emacs 29+) | — |
| eglot | LSP クライアント (内蔵) | `C-c r` (rename), `C-c C-a` (actions) |
| envrc (direnv) | ディレクトリ単位の環境変数 | — |
| magit | Git 操作 | `C-x g` |
| diff-hl | 差分の行表示 | — |
| forge | GitHub PR/Issue | — |
| git-timemachine | ファイル履歴の閲覧 | `C-c g t` |
| projectile | プロジェクト管理 | `C-c p` (コマンドマップ) |
| vterm | ターミナル | `M-j` (トグル) |
| treemacs | ファイルツリー | `M-b` |
| ace-window | ウィンドウジャンプ | `M-o` |
| dape | DAP デバッガー | — |

**Python 開発**: `uv` 経由で pyright (LSP) を実行。`.venv` を自動検出。

### init-ai.el — AI 連携

| パッケージ | 説明 | キーバインド |
|-----------|------|-------------|
| gptel | Gemini LLM チャット | `C-c a g` (チャット), `C-c a s` (送信) |
| aider | AI ペアプログラミング | `C-c a a` (メニュー) |
| copilot | GitHub Copilot 補完 | `TAB` (承認), `C-f` (承認) |
| copilot-chat | GitHub Copilot Chat | `C-c a c` (チャット), `C-c a f` (修正), `C-c a o` (最適化), `C-c a p` (プロンプト) |

モデルは `M-x customize-group RET my-ai RET` でカスタマイズ可能。

### init-debug.el — 診断・デバッグ

| コマンド | 説明 |
|---------|------|
| `M-x my/system-health-check` | 全機能の網羅的診断レポート |
| `M-x my/toggle-debug-mode` | デバッグモードの ON/OFF |
| `M-x my/show-startup-log` | 起動ログの表示 |
| `M-x my/show-init-errors` | 起動時エラーの詳細表示 |
| `M-x my/measure-startup-time` | 起動時間プロファイル |
| `M-x my/show-missing-packages` | 未インストールパッケージの確認 |
| `M-x my/install-missing-packages` | パッケージの一括インストール |

## 秘匿情報 (.secret.el)

`.secret.el` は `.gitignore` で除外されており、API キー等を設定する:

```elisp
;; -*- lexical-binding: t -*-
(setenv "GEMINI_API_KEY" "your-gemini-api-key")
(setenv "GITHUB_TOKEN" "your-github-token")
```

## カスタマイズ

- `M-x customize` による設定変更は `custom.el` に保存される (init.el を汚さない)
- AI モデルの変更: `M-x customize-group RET my-ai`
- テーマの切替: `<F5>` で Modus Vivendi ↔ Modus Operandi をトグル

## トラブルシューティング

他環境での互換性に関する詳細な注意事項は [WARNING.md](WARNING.md) を参照してください。

### Emergency モード

起動時に致命的なエラーが発生すると、最小限の設定のみで起動する。`*Emacs Startup Log*` バッファにエラー詳細が表示される。

### よくある問題

| 症状 | 対処 |
|------|------|
| 初回起動でパッケージエラー | ネットワーク接続を確認し `M-x package-refresh-contents` |
| フォントが適用されない | HackGen Nerd Font をインストールして Emacs を再起動 |
| Tree-sitter のグラマーがない | `M-x my/treesit-install-all-languages` |
| SKK で変換できない | `M-x skk-get` で辞書をダウンロード |
| org-roam DB エラー | SQLite3 をインストールし `M-x org-roam-db-sync` |
| AI (gptel) が動かない | `.secret.el` に `GEMINI_API_KEY` を設定 |
| Copilot が動かない | `M-x copilot-login` で認証 |
| 設定を読み込まず起動したい | `emacs -q` |

### 診断コマンド

問題発生時は `M-x my/system-health-check` を実行すると、環境・ネットワーク・外部ツール・パッケージの状態を一覧で確認できる。

## ライセンス

MIT License
