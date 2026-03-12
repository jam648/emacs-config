;;; init-ai.el --- AI Integration: gptel (Gemini) & Aider -*- lexical-binding: t -*-
;; [前提] .secret.el で GEMINI_API_KEY が設定済みであること

;; =========================================================
;; 0. AI モデル共通設定 (ユーザー可変)
;; =========================================================
(defcustom my/ai-default-gemini-model 'gemini-3.1-flash-lite-preview
  "gptel で使用するデフォルトの Gemini モデル"
  :type 'symbol
  :group 'my-ai)

(defcustom my/ai-gemini-models
  '(gemini-3.1-flash-lite-preview
    gemini-3.1-flash
    gemini-2.5-flash)
  "gptel で選択可能な Gemini モデルのリスト"
  :type '(repeat symbol)
  :group 'my-ai)

(defcustom my/ai-aider-default-model "gemini/gemini-3.1-flash-lite-preview"
  "Aider で使用するデフォルトのモデル文字列"
  :type 'string
  :group 'my-ai)

(defcustom my/ai-aider-models
  '("gemini/gemini-3.1-flash-lite-preview"
    "gemini/gemini-3.1-flash"
    "gemini/gemini-2.5-flash")
  "Aider で選択可能なモデル文字列のリスト"
  :type '(repeat string)
  :group 'my-ai)

;; =========================================================
;; 1. gptel (Gemini LLM チャットクライアント)
;; =========================================================
(use-package gptel
  :init
  ;; gptel-model は :init で即時設定する。
  ;; :config 内に書くと遅延ロード時まで未設定になり、
  ;; ヘルスチェックで未設定と誤検出される。
  (setq gptel-model my/ai-default-gemini-model)

  :config
  ;; ── API キーの確認 ────────────────────────────────────
  (let ((key (getenv "GEMINI_API_KEY")))
    (cond
     ((not key)
      (warn "⚠️ GEMINI_API_KEY が設定されていません。.secret.el を確認してください。"))
     ((string-empty-p key)
      (warn "⚠️ GEMINI_API_KEY が空です。.secret.el を確認してください。"))))

  ;; ── バックエンド設定 (Gemini) ─────────────────────────
  (setq gptel-backend
        (gptel-make-gemini "Gemini"
          :key    (getenv "GEMINI_API_KEY")
          :stream t
          :models my/ai-gemini-models))

  ;; ── UI 設定 ──────────────────────────────────────────
  (setq gptel-default-mode 'org-mode)

  ;; システムプロンプト集
  (setq gptel-directives
        '((default
            . "You are a helpful, precise, and concise assistant. \
When writing code, always include comments explaining key decisions. \
For Japanese text, respond in Japanese.")
          (coding
            . "You are an expert programmer. \
Provide clean, idiomatic, well-commented code. \
Always consider edge cases and error handling.")
          (writing
            . "You are a skilled editor. \
Help improve writing while preserving the author's voice. \
Point out unclear passages and suggest alternatives.")
          (japanese
            . "あなたは優秀な日本語アシスタントです。\
日本語で回答してください。技術的な内容も日本語で詳しく説明します。")))

  :bind
  (("C-c a g" . gptel)
   ("C-c a s" . gptel-send)
   ("C-c a m" . gptel-menu)))

;; =========================================================
;; 2. Aider (AI ペアプログラミング)
;; =========================================================
(use-package aider
  :ensure nil
  :init
  ;; インストール済みでなければ一度だけインストール
  (unless (or (package-installed-p 'aider)
              (locate-library "aider"))
    (package-vc-install "https://github.com/tninja/aider.el"))

  :config
  ;; ── モデル設定 ──────────────────────────────────────
  (setq aider-args
        (list "--model" my/ai-aider-default-model
              "--no-auto-commits"
              "--no-analytics"))

  (setq aider-popular-models my/ai-aider-models)

  ;; GEMINI_API_KEY を aider プロセスに確実に引き継ぐ
  (when (getenv "GEMINI_API_KEY")
    (setenv "GEMINI_API_KEY" (getenv "GEMINI_API_KEY")))

  :bind
  (("C-c a a" . aider-transient-menu)))

;; =========================================================
;; 3. GitHub Copilot (インラインコード補完)
;; =========================================================
(use-package copilot
  :ensure nil
  :init
  ;; vc-use-package 経由で GitHub から直接インストール
  (unless (or (package-installed-p 'copilot)
              (locate-library "copilot"))
    (package-vc-install "https://github.com/copilot-emacs/copilot.el"))
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>"   . 'copilot-accept-completion)
              ("TAB"     . 'copilot-accept-completion)
              ("C-<right>" . 'copilot-accept-completion-by-word)
              ("C-f"     . 'copilot-accept-completion)))

;; =========================================================
;; 4. GitHub Copilot Chat (対話・コード書き換え)
;; =========================================================
(use-package copilot-chat
  :ensure nil
  :init
  ;; vc-use-package でインストール
  (unless (or (package-installed-p 'copilot-chat)
              (locate-library "copilot-chat"))
    (package-vc-install "https://github.com/chep/copilot-chat.el"))

  :config
  ;; GitHub Copilot で提供されている Claude モデルを指定
  ;; ※ M-x copilot-chat-switch-model で他のモデル（gpt-4o 等）にも切り替え可能
  (setq copilot-chat-model "claude-4.6-sonnet")

  :bind
  (("C-c a c" . copilot-chat-display)      ;; チャット画面を開く
   ("C-c a p" . copilot-chat-custom-prompt-selection) ;; 選択範囲に指示を出して書き換え提案
   ("C-c a f" . copilot-chat-fix)          ;; 選択範囲のバグ修正を依頼
   ("C-c a o" . copilot-chat-optimize)))   ;; 選択範囲のリファクタリングを依頼

(provide 'init-ai)
;;; init-ai.el ends here