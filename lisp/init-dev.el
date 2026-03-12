;;; init-dev.el --- Dev Env: LSP, Git, Terminal, Debugger, HealthCheck -*- lexical-binding: t -*-

;; =========================================================
;; 1. Tree-sitter
;; =========================================================
(when (>= emacs-major-version 29)
  (setq treesit-language-source-alist
        '((bash       "https://github.com/tree-sitter/tree-sitter-bash")
          (c          "https://github.com/tree-sitter/tree-sitter-c")
          (cpp        "https://github.com/tree-sitter/tree-sitter-cpp")
          (css        "https://github.com/tree-sitter/tree-sitter-css")
          (go         "https://github.com/tree-sitter/tree-sitter-go")
          (html       "https://github.com/tree-sitter/tree-sitter-html")
          (javascript "https://github.com/tree-sitter/tree-sitter-javascript"
                      "master" "src")
          (json       "https://github.com/tree-sitter/tree-sitter-json")
          (python     "https://github.com/tree-sitter/tree-sitter-python")
          (rust       "https://github.com/tree-sitter/tree-sitter-rust")
          (toml       "https://github.com/tree-sitter/tree-sitter-toml")
          (tsx        "https://github.com/tree-sitter/tree-sitter-typescript"
                      "master" "tsx/src")
          (typescript "https://github.com/tree-sitter/tree-sitter-typescript"
                      "master" "typescript/src")
          (yaml       "https://github.com/ikatyang/tree-sitter-yaml"))))

(use-package treesit-auto
  :if (>= emacs-major-version 29)
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(defun my/treesit-install-all-languages ()
  "全ての tree-sitter グラマーをまとめてインストールする。"
  (interactive)
  (when (>= emacs-major-version 29)
    (dolist (lang (mapcar #'car treesit-language-source-alist))
      (unless (treesit-language-available-p lang)
        (message "Installing tree-sitter grammar for %s..." lang)
        (condition-case err
            (treesit-install-language-grammar lang)
          (error
           (message "⚠️ Failed to install %s: %s" lang
                    (error-message-string err))))))
    (message "✓ Tree-sitter grammar installation complete!")))

;; =========================================================
;; 2. exec-path-from-shell (Linux GUI でも有効化)
;; =========================================================
(use-package exec-path-from-shell
  :if (and (eq system-type 'gnu/linux)
           (or (display-graphic-p)
               (and (file-exists-p "/proc/version")
                    (with-temp-buffer
                      (ignore-errors (insert-file-contents "/proc/version"))
                      (search-forward "Microsoft" nil t)))))
  :config
  (dolist (var '("PATH" "MANPATH" "GOPATH" "CARGO_HOME" "RUSTUP_HOME"
                 "GEMINI_API_KEY" "GITHUB_TOKEN"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize)
  (message "✓ exec-path-from-shell: Linux GUI / WSL PATH 同期完了"))

;; =========================================================
;; 3. Eglot (LSP クライアント)
;; =========================================================
(use-package eglot
  :ensure nil
  :hook
  ((rust-ts-mode       . eglot-ensure)
   (typescript-ts-mode . eglot-ensure)
   (tsx-ts-mode        . eglot-ensure)
   (js-ts-mode         . eglot-ensure)
   (python-ts-mode     . eglot-ensure)
   (python-mode        . eglot-ensure))

  :bind (:map eglot-mode-map
              ("C-c r"   . eglot-rename)
              ("C-c C-f" . eglot-format)
              ("C-c C-a" . eglot-code-actions)
              ("C-c C-d" . eldoc))

  :config
  ;; ★Emacs 30 Ready: eglot-events-buffer-config (Emacs 29.1+) と
  ;;   後方互換のある eglot-events-buffer-size の両方をガードで切り替え
  (if (boundp 'eglot-events-buffer-config)
      (setq eglot-events-buffer-config '(:size 0 :format full))
    (setq eglot-events-buffer-size 0))

  (setq eglot-autoshutdown    t)
  (setq eglot-sync-connect    nil)
  (setq eglot-connect-timeout 15)

  (setq eglot-ignored-server-capabilities
        '(:documentFormattingProvider
          :documentRangeFormattingProvider))

  ;; ── Python (pyright via uv) ─────────────────────────────
  ;;
  ;; --from pyright: PyPI パッケージ名は "pyright"
  ;; pyright-langserver: そのパッケージが提供する LSP サーバーコマンド名
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("uv" "tool" "run" "--from" "pyright"
                    "pyright-langserver" "--stdio")))

  (add-to-list 'eglot-server-programs
               '((rust-mode rust-ts-mode)
                 . ("rust-analyzer")))

  (add-to-list 'eglot-server-programs
               '((typescript-ts-mode tsx-ts-mode js-ts-mode)
                 . ("typescript-language-server" "--stdio")))

  (defun my/eglot-python-venv-setup ()
    "Detect Python virtual environment and configure Eglot/pyright."
    (when-let ((venv (or
                      (getenv "VIRTUAL_ENV")
                      (when-let ((root (locate-dominating-file
                                        default-directory ".venv")))
                        (expand-file-name ".venv" root)))))
      (setq-local eglot-workspace-configuration
                  `((:pyright
                     (:pythonPath ,(expand-file-name "bin/python" venv)
                      :analysis   (:typeCheckingMode "basic"
                                   :autoImportCompletions t)))))))

  (add-hook 'python-mode-hook    #'my/eglot-python-venv-setup)
  (add-hook 'python-ts-mode-hook #'my/eglot-python-venv-setup)

  (when (fboundp 'eglot-inlay-hints-mode)
    (add-hook 'typescript-ts-mode-hook #'eglot-inlay-hints-mode)
    (add-hook 'tsx-ts-mode-hook        #'eglot-inlay-hints-mode)))

;; =========================================================
;; 4. 環境変数管理 (direnv / .envrc)
;; =========================================================
(use-package envrc
  :hook (after-init . envrc-global-mode))

;; =========================================================
;; 5. Python 開発ツール
;; =========================================================
(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-mode)
  :config
  (setq python-indent-guess-indent-offset nil)
  (setq python-indent-offset 4))

(use-package py-isort
  :if (or (executable-find "isort") (executable-find "uv"))
  :hook ((python-mode    . py-isort-before-save)
         (python-ts-mode . py-isort-before-save))
  :config
  (setq py-isort-options '("--profile" "black")))

(use-package pytest
  :hook ((python-mode    . my/pytest-setup-keys)
         (python-ts-mode . my/pytest-setup-keys))
  :config
  (defun my/pytest-setup-keys ()
    (local-set-key (kbd "C-c t t") #'pytest-one)
    (local-set-key (kbd "C-c t f") #'pytest-module)
    (local-set-key (kbd "C-c t a") #'pytest-all)))

;; =========================================================
;; 6. 言語別サポートパッケージ
;; =========================================================
(use-package rust-mode
  :mode "\\.rs\\'"
  :config
  (when (and (>= emacs-major-version 29)
             (treesit-language-available-p 'rust))
    (setq rust-mode-treesitter-derive t)))

(use-package web-mode
  :mode (("\\.html?\\'" . web-mode)
         ("\\.css\\'"   . web-mode))
  :config
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset    2)
  (setq web-mode-code-indent-offset   2))

;; =========================================================
;; 7. Git 連携
;; =========================================================
(use-package magit
  :bind ("C-x g" . magit-status)
  :config
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1))

(use-package diff-hl
  :init (global-diff-hl-mode)
  :hook ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode         . diff-hl-dired-mode))
  :config
  (diff-hl-flydiff-mode)
  (diff-hl-margin-mode)
  (setq diff-hl-margin-symbols-alist
        '((insert . "│") (delete . "│") (change . "│"))))

;; =========================================================
;; Forge (GitHub PR/Issue 管理)
;; =========================================================
(use-package forge
  :defer nil
  :after magit
  :config
  (setq forge-topic-list-limit '(60 . 0))
  (when (getenv "GITHUB_TOKEN")
    (message "✓ Forge: GITHUB_TOKEN detected")))

(use-package git-timemachine
  :bind ("C-c g t" . git-timemachine))

;; =========================================================
;; 8. プロジェクト管理 (Projectile)
;; =========================================================
(use-package projectile
  :init (projectile-mode +1)
  :bind (:map projectile-mode-map
              ("C-c p" . projectile-command-map))
  :config
  (setq projectile-enable-caching  t)
  (setq projectile-indexing-method 'alien)
  (setq projectile-project-root-files-bottom-up
        '(".projectile" ".git" ".hg" ".svn"
          "pyproject.toml" "setup.py" "Cargo.toml")))

;; =========================================================
;; 9. ターミナル (vterm)
;; =========================================================
(use-package vterm
  :config
  (setq vterm-shell (or (getenv "SHELL") "/bin/zsh"))
  (setq vterm-max-scrollback 10000))

(use-package vterm-toggle
  :bind ("M-j" . vterm-toggle)
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (setq vterm-toggle-scope        'project))

;; =========================================================
;; 10. ファイルツリー (Treemacs)
;; =========================================================
(use-package treemacs
  :bind ("M-b" . treemacs)
  :config
  (setq treemacs-width             30)
  (setq treemacs-show-hidden-files  t)
  (setq treemacs-follow-after-init  t)
  (treemacs-follow-mode    t)
  (treemacs-filewatch-mode t))

(use-package treemacs-nerd-icons
  :after treemacs
  :config (treemacs-load-theme "nerd-icons"))

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

;; =========================================================
;; 11. ウィンドウ管理
;; =========================================================
(use-package ace-window
  :bind ("M-o" . ace-window)
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

;; =========================================================
;; 12. コードコメントのハイライト (hl-todo)
;; =========================================================
(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :config
  (setq hl-todo-keyword-faces
        '(("TODO"       . "#FF6B6B")
          ("FIXME"      . "#FF6B6B")
          ("HACK"       . "#FFA500")
          ("NOTE"       . "#98C379")
          ("REVIEW"     . "#C678DD")
          ("DEPRECATED" . "#808080"))))

;; =========================================================
;; 13. デバッガー (Dape / DAP Protocol)
;; =========================================================
(use-package dape
  :config
  (setq dape-buffer-window-arrangement 'right)
  (when (>= emacs-major-version 29)
    (setq dape-inlay-hints t))

  (add-to-list 'dape-configs
               `(debugpy
                 modes (python-mode python-ts-mode)
                 command "uv"
                 command-args ("tool" "run" "--from" "debugpy"
                               "debugpy"
                               "--listen"         "127.0.0.1:5678"
                               "--wait-for-client")
                 :type    "python"
                 :request "launch"
                 :cwd     dape-cwd-fn
                 :program dape-find-file-buffer-default))

  (add-hook 'dape-stopped-hook #'dape-info)
  (add-hook 'dape-compile-hook #'kill-buffer))

;; =========================================================
;; 14. システム診断 (M-x my/system-health-check)
;; =========================================================
;; 環境・ネットワーク・外部ツール・パッケージの状態を網羅的にチェックする。
;; 手動実行のみ。起動時の自動実行は行わない。

;; ── ネットワーク疎通チェック用ヘルパー ───────────────────────
(defun my/check-url-sync (url &optional timeout-sec)
  "URL への HTTP 接続を TIMEOUT-SEC 秒以内に試み、結果文字列を返す。"
  (let ((start   (current-time))
        (timeout (or timeout-sec 3)))
    (condition-case err
        (with-timeout (timeout "timeout")
          (let ((buf (url-retrieve-synchronously url :silent :inhibit-cookies)))
            (if buf
                (progn
                  (kill-buffer buf)
                  (format "✅ OK (%d ms)"
                          (round (* 1000 (float-time (time-since start))))))
              "❌ No response")))
      (error
       (if (string= (error-message-string err) "timeout")
           (format "❌ Timeout (%ds)" timeout)
         (format "❌ %s" (error-message-string err)))))))

;; ── pyright 起動確認ヘルパー ────────────────────────────────
;; call-process の終了コードで判定 (0=成功)。
;; 文字列マッチだとエラーメッセージでも偽陽性が出るため。
(defun my/hc--check-pyright ()
  "uv 経由で pyright が正常に起動できるか確認する。
call-process の終了コードで判定し、結果文字列を返す。"
  (if (not (executable-find "uv"))
      "❌ uv not found"
    (let* ((out-buf   (generate-new-buffer " *pyright-check*"))
           (exit-code (condition-case _
                          (with-timeout (15 'timeout)
                            (call-process "uv" nil out-buf nil
                                          "tool" "run" "--from" "pyright"
                                          "pyright" "--version"))
                        (error 'error)))
           (output    (with-current-buffer out-buf
                        (string-trim (buffer-string)))))
      (kill-buffer out-buf)
      (cond
       ((eq exit-code 'timeout)
        "⚠️ Timeout (15s) - ネットワーク or パッケージダウンロード中？")
       ((eq exit-code 'error)
        "❌ call-process エラー")
       ((eq exit-code 0)
        (format "✅ %s" (if (string-empty-p output) "OK" output)))
       (t
        (let ((first-line (car (split-string output "\n" t))))
          (format "❌ 起動失敗 (exit=%d%s)"
                  exit-code
                  (if first-line
                      (format " | %s"
                              (truncate-string-to-width first-line 60 nil nil "…"))
                    ""))))))))

;; ── ヘルスチェック内部ヘルパー ─────────────────────────────────
(defun my/hc--safe-insert (name thunk)
  "THUNK を実行してバッファに挿入し、エラー時は失敗メッセージを挿入する。
成功時は t、失敗時は (cons name err) を返す。"
  (condition-case err
      (progn (funcall thunk) t)
    (error
     (insert (format "- ✗ [%s]: ロード失敗 (エラー内容: %s)\n"
                     name (error-message-string err)))
     (cons name err))))

;; ── メインの health check 関数 ────────────────────────────────
(defun my/system-health-check ()
  "Emacs の全機能を網羅的にテストし、専用バッファにレポートを表示する。
各ステップを condition-case で保護し、1つのエラーで全体がクラッシュしない。
M-x my/system-health-check で手動実行する。"
  (interactive)
  (message "🔍 System Health Check 実行中... (ネットワーク確認に数秒かかります)")
  (let ((buf    (get-buffer-create "*System Health Check*"))
        (errors '()))

    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)

        ;; ── org-mode 起動 (失敗時は text-mode にフォールバック) ──
        (let ((r (my/hc--safe-insert
                  "org-mode 起動"
                  (lambda () (org-mode)))))
          (when (consp r)
            (push r errors)
            (text-mode)
            (insert "⚠️ org-mode 起動失敗。text-mode で続行します。\n\n")))

        ;; ── ヘッダー ──────────────────────────────────────────
        (let ((r (my/hc--safe-insert "ヘッダー"
                  (lambda ()
                    (insert "#+TITLE: Emacs System Health Check\n")
                    (insert (format "#+DATE: %s\n\n" (format-time-string "%Y-%m-%d %H:%M:%S")))
                    (insert (format "- Emacs: =%s=\n" emacs-version))
                    (insert (format "- System: =%s=\n" system-type))
                    (insert (format "- Init time: =%s=\n\n" (emacs-init-time)))))))
          (when (consp r) (push r errors)))

        ;; ── Core ──
        (let ((r (my/hc--safe-insert "Core"
                  (lambda ()
                    (insert "* Core\n\n")
                    (insert (format "- Tree-sitter: %s\n"
                                    (if (and (>= emacs-major-version 29) (treesit-available-p))
                                        "✅ Available" "❌ Not available")))
                    (when (fboundp 'my/wsl-p)
                      (insert (format "- Environment: %s\n"
                                      (cond ((my/wsl-p)   "✅ WSL")
                                            ((my/macos-p) "✅ macOS")
                                            (t            "✅ Linux")))))
                    (insert (format "- Display: %s\n"
                                    (if (display-graphic-p) "✅ GUI" "⚠️ Terminal (TUI)")))
                    (insert (format "- daemon mode: %s\n"
                                    (if (daemonp) "✅ Running as daemon" "— Normal mode")))))))
          (when (consp r) (push r errors)))

        ;; ── Network ──
        (let ((r (my/hc--safe-insert "Network"
                  (lambda ()
                    (insert "\n* Network\n\n")
                    (insert "（各 URL に接続確認中。最大 3秒/件）\n\n")
                    (dolist (entry '(("Google" "https://www.google.com")
                                     ("GitHub" "https://github.com")
                                     ("MELPA"  "https://melpa.org")))
                      (insert (format "- %s :: %s\n"
                                      (car entry)
                                      (my/check-url-sync (cadr entry) 3))))))))
          (when (consp r) (push r errors)))

        ;; ── External Tools ──
        (let ((r (my/hc--safe-insert "External Tools"
                  (lambda ()
                    (insert "\n* External Tools\n\n** 必須ツール\n\n")
                    (dolist (tool '(("git"     "Git")
                                    ("rg"      "ripgrep")
                                    ("fd"      "fd")
                                    ("uv"      "uv (Python管理)")
                                    ("python3" "Python 3")))
                      (let* ((cmd  (car tool))
                             (desc (cadr tool))
                             (path (executable-find cmd)))
                        (insert (format "- %s :: %s\n"
                                        desc
                                        (if path
                                            (format "✅ =%s=" path)
                                          (format "❌ NOT FOUND =(%s)=" cmd))))))
                    (insert "\n** オプションツール (未インストールでも正常)\n\n")
                    (dolist (tool '(("node"                       "Node.js")
                                    ("rust-analyzer"              "rust-analyzer")
                                    ("typescript-language-server" "TypeScript LSP")
                                    ("pandoc"                     "Pandoc")))
                      (let* ((cmd  (car tool))
                             (desc (cadr tool))
                             (path (executable-find cmd)))
                        (insert (format "- %s :: %s\n"
                                        desc
                                        (if path
                                            (format "✅ =%s=" path)
                                          "⚪️ Optional (not installed)")))))
                    (insert "\n** uv pyright 起動テスト\n\n")
                    (insert (format "- pyright :: %s\n" (my/hc--check-pyright)))))))
          (when (consp r) (push r errors)))

        ;; ── Tree-sitter Grammars ──
        (let ((r (my/hc--safe-insert "Tree-sitter Grammars"
                  (lambda ()
                    (insert "\n* Tree-sitter Grammars\n\n")
                    (if (and (>= emacs-major-version 29) (treesit-available-p))
                        (dolist (lang '(python rust typescript tsx javascript json yaml bash toml))
                          (insert (format "- %s :: %s\n" lang
                                          (if (treesit-language-available-p lang)
                                              "✅ Installed"
                                            "❌ Missing → =M-x my/treesit-install-all-languages="))))
                      (insert "- ❌ Tree-sitter not available\n"))))))
          (when (consp r) (push r errors)))

        ;; ── AI Integration ──
        (let ((r (my/hc--safe-insert "AI Integration"
                  (lambda ()
                    (insert "\n* AI Integration\n\n")
                    (insert (format "- gptel package :: %s\n"
                                    (if (featurep 'gptel) "✅ Loaded" "⚠️ Not yet loaded (defer)")))
                    (let ((key (getenv "GEMINI_API_KEY")))
                      (insert (format "- GEMINI_API_KEY :: %s\n"
                                      (cond ((not key)            "❌ NOT SET")
                                            ((string-empty-p key) "❌ EMPTY")
                                            ((< (length key) 20)  "⚠️ SET (短すぎる・要確認)")
                                            (t (format "✅ SET (len=%d, prefix=%s…)"
                                                       (length key)
                                                       (substring key 0 (min 8 (length key)))))))))
                    (insert (format "- gptel-model :: %s\n"
                                    (if (and (boundp 'gptel-model) gptel-model)
                                        (format "✅ =%s= (type: %s)" gptel-model (type-of gptel-model))
                                      "❌ Not configured")))
                    (insert "- API reachability :: ⏭️ Skipped (quota 節約。実確認: =M-x gptel=)\n")))))
          (when (consp r) (push r errors)))

        ;; ── Notes ──
        (let ((r (my/hc--safe-insert "Notes"
                  (lambda ()
                    (insert "\n* Notes\n\n")
                    (dolist (entry `(("org-directory"
                                      ,(if (boundp 'org-directory) org-directory nil))
                                     ("org-roam-directory"
                                      ,(if (boundp 'org-roam-directory) org-roam-directory nil))))
                      (let* ((label (car entry))
                             (path  (cadr entry)))
                        (insert (format "- %s :: %s\n" label
                                        (cond ((not path)                  "❌ Not configured")
                                              ((not (file-exists-p path))  (format "⚠️ NOT FOUND (未作成): =%s=" path))
                                              ((not (file-writable-p path)) (format "⚠️ NOT WRITABLE: =%s=" path))
                                              (t (format "✅ =%s=" path)))))))
                    (insert (format "- org-roam DB :: %s\n"
                                    (if (featurep 'org-roam)
                                        "✅ Loaded (=M-x org-roam-db-sync= で強制同期可)"
                                      "⚠️ Not yet loaded (defer)")))
                    (insert (format "- consult-org-roam :: %s\n"
                                    (if (featurep 'consult-org-roam) "✅ Loaded" "⚠️ Not yet loaded (defer)")))))))
          (when (consp r) (push r errors)))

        ;; ── Development ──
        (let ((r (my/hc--safe-insert "Development"
                  (lambda ()
                    (insert "\n* Development\n\n")
                    (insert (format "- Eglot (current buffer) :: %s\n"
                                    (if (bound-and-true-p eglot--managed-mode)
                                        (format "✅ Active | Server: %s" (ignore-errors (eglot-current-server)))
                                      "— Not active in current buffer")))
                    (let ((venv (or (getenv "VIRTUAL_ENV")
                                    (when-let ((root (locate-dominating-file default-directory ".venv")))
                                      (expand-file-name ".venv" root)))))
                      (insert (format "- Python venv :: %s\n"
                                      (if venv (format "✅ =%s=" venv) "⚠️ Not detected"))))
                    (insert (format "- Rust (rustup) :: %s\n"
                                    (if (executable-find "rustup")
                                        (string-trim (shell-command-to-string "rustup --version 2>&1"))
                                      "⚪️ Optional (rustup not installed)")))
                    (insert (format "- Node.js :: %s\n"
                                    (if (executable-find "node")
                                        (string-trim (shell-command-to-string "node --version 2>&1"))
                                      "⚪️ Optional (not installed)")))))))
          (when (consp r) (push r errors)))

        ;; ── Apps ──
        (let ((r (my/hc--safe-insert "Apps"
                  (lambda ()
                    (insert "\n* Apps\n\n")
                    ;; SKK 辞書パスは init-input.el の skk-get-jisyo/ と整合
                    (let ((jisyo (locate-user-emacs-file "skk-get-jisyo/SKK-JISYO.L")))
                      (insert (format "- SKK 大辞書 :: %s\n"
                                      (if (file-exists-p jisyo)
                                          (format "✅ =%s= (%s bytes)" jisyo (file-attribute-size (file-attributes jisyo)))
                                        "❌ NOT FOUND → =M-x skk-get= でダウンロード"))))
                    (insert (format "- SKK display mode :: %s\n"
                                    (cond ((and (boundp 'skk-show-tooltip) skk-show-tooltip) "✅ tooltip (GUI)")
                                          ((and (boundp 'skk-show-inline) skk-show-inline)   (format "✅ inline/%s (Terminal)" skk-show-inline))
                                          (t "⚠️ unknown"))))
                    (insert (format "- org-pomodoro :: %s\n"
                                    (if (featurep 'org-pomodoro) "✅ Loaded" "— Not yet loaded (defer)")))
                    (insert (format "- Zone screensaver :: %s\n"
                                    (if (featurep 'zone)
                                        (if (and (boundp 'zone--timer) zone--timer)
                                            "✅ Armed (600s idle)" "✅ Loaded (timer status unknown)")
                                      "⚠️ Not loaded")))
                    (insert (format "- Nyan mode :: %s\n"
                                    (if (bound-and-true-p nyan-mode) "✅ Active" "❌ Inactive")))))))
          (when (consp r) (push r errors)))

        ;; ── WSL Integration ──
        (let ((r (my/hc--safe-insert "WSL Integration"
                  (lambda ()
                    (when (and (fboundp 'my/wsl-p) (my/wsl-p))
                      (insert "\n* WSL Integration\n\n")
                      (insert (format "- WSL user :: %s\n"
                                      (if (boundp 'my/wsl-windows-user)
                                          (format "✅ =%s=" my/wsl-windows-user)
                                        "❌ Not detected")))
                      (insert (format "- clipboard (win32yank) :: %s\n"
                                      (if (fboundp 'my/wsl-find-executable)
                                          (let ((path (my/wsl-find-executable "win32yank.exe")))
                                            (if path (format "✅ =%s=" path) "❌ NOT FOUND"))
                                        "❌ WSL functions not loaded")))
                      (insert (format "- browser (wslview) :: %s\n"
                                      (if (executable-find "wslview")
                                          (format "✅ =%s=" (executable-find "wslview"))
                                        "⚠️ NOT FOUND (=sudo apt install wslu=)")))
                      (insert (format "- DISPLAY :: %s\n"
                                      (let ((d (getenv "DISPLAY")))
                                        (if d (format "✅ =%s=" d) "⚠️ Not set")))))))))
          (when (consp r) (push r errors)))

        ;; ── エラーサマリー ──
        (when errors
          (insert "\n* ⚠️ Health Check Step Errors\n\n")
          (insert "以下のステップでエラーが発生しました。\n")
          (insert "各エラーをスキップして最後まで実行済みです。\n\n")
          (dolist (entry (nreverse errors))
            (insert (format "- ✗ [%s]: %s\n" (car entry) (error-message-string (cdr entry))))))

        ;; ── フッター ──
        (insert "\n-----\n")
        (insert (format "/Generated by Emacs v19.3 Health Check: %s/\n"
                        (format-time-string "%Y-%m-%d %H:%M:%S")))))

    (pop-to-buffer buf)
    (goto-char (point-min))
    (read-only-mode 1)
    (let ((n (length errors)))
      (if (zerop n)
          (message "✓ System Health Check 完了 (全ステップ正常)")
        (message "⚠️ System Health Check 完了 (%d ステップでエラー。レポートを確認)" n)))))

;; =========================================================
;; 15. 旧コマンドとの互換性エイリアス
;; =========================================================
(defalias 'my/diagnose-dev-setup #'my/system-health-check)

;; =========================================================
;; 16. ヘルスチェック: バックグラウンド版
;; =========================================================
;; 起動時の自動実行は行わない。M-x で手動実行する。

(defvar my/health-check-log-file
  (expand-file-name "var/health-check.log" user-emacs-directory)
  "ヘルスチェック結果を保存するファイル。")

(defvar my/health-check-last-result nil
  "前回のヘルスチェック結果 (文字列)。")

(defun my/system-health-check-background ()
  "バックグラウンド用ヘルスチェック (簡易版)。
結果を `my/health-check-log-file' に保存する。
必要時に手動で M-x で呼び出す。"
  (interactive)
  (message "🔍 Background health check running...")

  (when (file-exists-p my/health-check-log-file)
    (setq my/health-check-last-result
          (with-temp-buffer
            (insert-file-contents my/health-check-log-file)
            (buffer-string))))

  (let ((log-dir (file-name-directory my/health-check-log-file)))
    (unless (file-exists-p log-dir)
      (make-directory log-dir t)))

  (let ((buf (get-buffer-create "*System Health Check*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)

        ;; org-mode を安全に起動
        (condition-case err
            (org-mode)
          (error
           (text-mode)
           (message "⚠️ Background health check: org-mode 起動失敗 (%s). text-mode で継続。"
                    (error-message-string err))))

        (condition-case err
            (progn
              (insert "#+TITLE: Emacs v19.3 System Health Check (Background)\n")
              (insert (format "#+DATE: %s\n\n" (format-time-string "%Y-%m-%d %H:%M:%S")))
              (insert (format "- Emacs: =%s=\n" emacs-version))
              (insert (format "- System: =%s=\n" system-type))
              (insert (format "- Init time: =%s=\n\n" (emacs-init-time))))
          (error (insert (format "Header error: %s\n\n" (error-message-string err)))))

        (condition-case err
            (progn
              (insert "* Core\n\n")
              (insert (format "- Tree-sitter: %s\n"
                              (if (and (>= emacs-major-version 29) (treesit-available-p))
                                  "✅ Available" "❌ Not available")))
              (when (fboundp 'my/wsl-p)
                (insert (format "- Environment: %s\n"
                                (cond ((my/wsl-p)   "✅ WSL")
                                      ((my/macos-p) "✅ macOS")
                                      (t            "✅ Linux")))))
              (insert (format "- Display: %s\n"
                              (if (display-graphic-p) "✅ GUI" "⚠️ Terminal"))))
          (error (insert (format "- ✗ [Core]: %s\n" (error-message-string err)))))

        (condition-case err
            (progn
              (insert "\n* Packages\n\n")
              (insert (format "- Loaded: %d packages\n"
                              (length package-activated-list))))
          (error (insert (format "- ✗ [Packages]: %s\n" (error-message-string err)))))

        (condition-case err
            (progn
              (insert "\n* Modules\n\n")
              (dolist (mod '(init-core init-ui init-completion init-edit
                             init-input init-notes init-dev init-ai init-debug))
                (insert (format "- %s :: %s\n" mod (if (featurep mod) "✅" "❌")))))
          (error (insert (format "- ✗ [Modules]: %s\n" (error-message-string err)))))

        (insert "\n---\n")
        (insert (format "/Generated: %s/\n" (format-time-string "%Y-%m-%d %H:%M:%S")))

        (condition-case err
            (write-region (point-min) (point-max)
                          my/health-check-log-file nil 'silent)
          (error
           (message "⚠️ Health check log save failed: %s"
                    (error-message-string err))))))))

(provide 'init-dev)
;;; init-dev.el ends here
