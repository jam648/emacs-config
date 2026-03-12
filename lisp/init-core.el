;;; init-core.el --- Core: Package Management, Env Detection, Fonts, Base -*- lexical-binding: t -*-

;; =========================================================
;; 1. パッケージ管理の初期化
;; =========================================================
(require 'package)
(add-to-list 'package-archives '("melpa"  . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/") t)
(package-initialize)

;; 初回起動時のみパッケージリストを更新
(unless package-archive-contents
  (package-refresh-contents))

;; use-package の自動インストール
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t)
(setq use-package-verbose nil)

;; vc-use-package: :vc キーワードを use-package で使えるようにする
;; (Emacs 30+ では標準搭載)
(unless (or (package-installed-p 'vc-use-package)
            (>= emacs-major-version 30))
  (package-vc-install "https://github.com/slotThe/vc-use-package"))
(unless (>= emacs-major-version 30)
  (require 'vc-use-package))

;; =========================================================
;; 2. 起動パフォーマンス最適化
;; =========================================================

(use-package gcmh
  :init (gcmh-mode 1)
  :config
  (setq gcmh-idle-delay 5)
  (setq gcmh-high-cons-threshold (* 64 1024 1024)))

(use-package so-long
  :ensure nil
  :config (global-so-long-mode 1))

;; =========================================================
;; 3. 環境判別ユーティリティ
;; =========================================================

(defun my/wsl-p ()
  "WSL (Windows Subsystem for Linux) 上で動いているか判定する。"
  (and (eq system-type 'gnu/linux)
       (or (file-exists-p "/proc/sys/fs/binfmt_misc/WSLInterop")
           (and (file-readable-p "/proc/version")
                (with-temp-buffer
                  (insert-file-contents "/proc/version")
                  (search-forward "Microsoft" nil t))))))

(defun my/macos-p ()
  "macOS 上で動いているか判定する。"
  (eq system-type 'darwin))

;; =========================================================
;; 4. MacOS 設定
;; =========================================================
(when (my/macos-p)
  ;; REFACTOR_SPEC 準拠: Option=Meta, Command=Super
  (setq mac-option-modifier  'meta)
  (setq mac-command-modifier 'super)

  ;; シェルの PATH などの環境変数を Emacs に引き継ぐ (GUI起動時は必須)
  (use-package exec-path-from-shell
    :if (memq window-system '(mac ns x))
    :config
    (dolist (var '("PATH" "MANPATH" "GOPATH" "CARGO_HOME" "RUSTUP_HOME"
                   "GEMINI_API_KEY" "GITHUB_TOKEN"))
      (add-to-list 'exec-path-from-shell-variables var))
    (exec-path-from-shell-initialize)))

;; =========================================================
;; 5. WSL 完全攻略 (Aggressive WSL Integration)
;; =========================================================
(when (my/wsl-p)

  ;; ── WSL ユーザー名の解決 ──────────────────────────────
  ;; $USERNAME (Windows側) → $USER → whoami の順で取得
  (defvar my/wsl-windows-user
    (or (getenv "USERNAME")
        (getenv "USER")
        (string-trim (shell-command-to-string "whoami")))
    "WSL 環境下での Windows ユーザー名。")

  ;; ── 総当たりパス探索関数 ─────────────────────────────
  (defun my/wsl-find-executable (filename)
    "WSL 環境下で FILENAME を Windows 側を含む複数パスから探索して返す。
見つからなければ nil を返す。executable-find だけに頼らない徹底的探索。
★v19.2: file-executable-p にガードを追加 (存在しないパスでのエラー回避)。"
    (let ((candidates
           (list
            ;; ---- 標準 PATH -------------------------
            (executable-find filename)
            ;; ---- System32 / Windows ----------------
            (concat "/mnt/c/Windows/System32/" filename)
            (concat "/mnt/c/Windows/"          filename)
            ;; ---- Scoop (ユーザー) ------------------
            (concat "/mnt/c/Users/" my/wsl-windows-user "/scoop/shims/" filename)
            ;; ---- Scoop (グローバル) ----------------
            (concat "/mnt/c/ProgramData/scoop/shims/" filename)
            ;; ---- winget / AppData ------------------
            (concat "/mnt/c/Users/" my/wsl-windows-user
                    "/AppData/Local/Microsoft/WindowsApps/" filename)
            ;; ---- WSL 標準ツール --------------------
            (concat "/usr/local/bin/" filename)
            (concat "/usr/bin/"       filename))))
      (cl-find-if (lambda (path)
                    (and path
                         ;; Critical-3 修正: 存在しないパスで error を投げないよう guard
                         (condition-case nil
                             (file-executable-p path)
                           (error nil))))
                  candidates)))

  ;; ── クリップボード連携 (win32yank.exe) ──────────────
  ;; win32yank.exe が見つかれば Emacs のクリップボード処理をフック
  (let ((win32yank (my/wsl-find-executable "win32yank.exe")))
    (if win32yank
        (progn
          (setq interprogram-cut-function
                (lambda (text)
                  (let ((process-connection-type nil))
                    (let ((proc (start-process "win32yank-in" nil win32yank "-i" "--crlf")))
                      (process-send-string proc text)
                      (process-send-eof proc)))))
          (setq interprogram-paste-function
                (lambda ()
                  (let ((out (shell-command-to-string
                              (concat win32yank " -o --lf"))))
                    (when (and out (not (string-empty-p out)))
                      out))))
          (message "✓ WSL Clipboard: win32yank.exe linked (%s)" win32yank))
      ;; フォールバック: xclip / xsel を試みる
      (cond
       ((executable-find "xclip")
        (setq xclip-program "xclip")
        (when (fboundp 'xclip-mode) (xclip-mode 1))
        (message "✓ WSL Clipboard: xclip fallback"))
       ((executable-find "xsel")
        (message "✓ WSL Clipboard: xsel fallback (manual setup required)"))
       (t
        (message "⚠️ WSL Clipboard: no clipboard tool found (install win32yank.exe or xclip)")))))

  ;; ── ブラウザ連携 (wslview) ──────────────────────────
  ;; wslview: Windows 側のデフォルトブラウザを開く WSL ツール
  (let ((wslview (or (executable-find "wslview")
                     (my/wsl-find-executable "wslview"))))
    (if wslview
        (progn
          (setq browse-url-browser-function #'browse-url-generic)
          (setq browse-url-generic-program wslview)
          (message "✓ WSL Browser: wslview linked (%s)" wslview))
      ;; フォールバック: powershell.exe 経由でブラウザを開く
      (let ((powershell (my/wsl-find-executable "powershell.exe")))
        (when powershell
          (setq browse-url-browser-function
                (lambda (url &optional _new-window)
                  (call-process powershell nil nil nil
                                "-Command"
                                (format "Start-Process '%s'" url))))
          (message "✓ WSL Browser: powershell.exe fallback (%s)" powershell)))))

  ;; ── PowerShell 連携 ─────────────────────────────────
  (let ((ps (my/wsl-find-executable "powershell.exe")))
    (when ps
      (setenv "WINDOWS_POWERSHELL" ps)
      (message "✓ WSL PowerShell: %s" ps)))

  ;; ── open-file-with-windows-app ───────────────────────
  ;; Windows アプリでファイルを開くコマンド (explorer.exe 経由)
  (let ((explorer (or (my/wsl-find-executable "explorer.exe")
                      (my/wsl-find-executable "cmd.exe"))))
    (when explorer
      (defun my/wsl-open-with-windows (file)
        "WSL から Windows アプリでファイルを開く。"
        (interactive "fOpen with Windows: ")
        (call-process explorer nil nil nil
                      (replace-regexp-in-string "/" "\\\\" file)))))

  ;; ── WSL 固有の環境変数を補完 ────────────────────────
  ;; DISPLAY 未設定なら X11 サーバーのデフォルト値を設定
  (unless (getenv "DISPLAY")
    (setenv "DISPLAY" ":0"))

  (message "✓ WSL Integration: complete (user=%s)" my/wsl-windows-user))

;; =========================================================
;; 6. フォント設定 (HackGen Nerd Font)
;; =========================================================
(defun my/setup-font ()
  "Setup HackGen Nerd Font. Works in both normal and daemon mode."
  (let ((font-name (cond
                    ((member "HackGen Console NF" (font-family-list))
                     "HackGen Console NF")
                    ((member "HackGen Nerd Font Mono" (font-family-list))
                     "HackGen Nerd Font Mono")
                    ((member "HackGen35 Nerd Font" (font-family-list))
                     "HackGen35 Nerd Font")
                    (t nil))))
    (if font-name
        (progn
          (set-face-attribute 'default     nil :family font-name :height 140)
          (set-face-attribute 'fixed-pitch nil :family font-name)
          (set-fontset-font t 'japanese-jisx0208 (font-spec :family font-name))
          (message "✓ Font: %s" font-name))
      (message "⚠️ Font: HackGen Nerd Font not found, using default"))))

;; デーモンモード対応：フレーム作成時にフォントを適用
(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame
                  (my/setup-font))))
  (my/setup-font))

;; =========================================================
;; 7. 文字コード設定
;; =========================================================
(set-language-environment "Japanese")
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)

;; =========================================================
;; 8. UI の基本設定
;; =========================================================
(setq inhibit-startup-message t)
(setq ring-bell-function 'ignore)

(tool-bar-mode   -1)
(menu-bar-mode   -1)
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(global-display-line-numbers-mode t)
(setq display-line-numbers-type t)
(column-number-mode t)

(show-paren-mode 1)
(setq show-paren-delay 0)

(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

;; =========================================================
;; 9. 基本的な編集設定
;; =========================================================
(defalias 'yes-or-no-p 'y-or-n-p)

(setq require-final-newline t)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq-default fill-column 80)

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
(setq mouse-wheel-progressive-speed nil)

;; =========================================================
;; 10. バックアップファイルの管理
;; =========================================================
(let ((backup-dir   (expand-file-name "var/backup/"   user-emacs-directory))
      (autosave-dir (expand-file-name "var/auto-save/" user-emacs-directory)))
  (dolist (dir (list backup-dir autosave-dir))
    (unless (file-exists-p dir)
      (make-directory dir t)))
  (setq backup-directory-alist         `(("." . ,backup-dir)))
  (setq auto-save-file-name-transforms `((".*" ,autosave-dir t))))

(setq bookmark-default-file (expand-file-name "var/bookmarks" user-emacs-directory))
(setq make-backup-files   t)
(setq version-control     t)
(setq kept-new-versions   5)
(setq kept-old-versions   2)
(setq delete-old-versions t)

;; =========================================================
;; 11. 履歴・セッション管理
;; =========================================================
(use-package savehist
  :ensure nil
  :init (savehist-mode)
  :config
  (setq savehist-additional-variables
        '(search-ring regexp-search-ring)))

(use-package recentf
  :ensure nil
  :config
  (recentf-mode 1)
  (setq recentf-max-saved-items 100)
  (setq recentf-exclude
        '("/tmp/" "/ssh:" "COMMIT_EDITMSG" "\\.git/"
          "\\elpa/" "\\.emacs\\.d/var/")))

(setq desktop-restore-eager 5)
(setq desktop-load-locked-desktop t)
(desktop-save-mode 1)

;; =========================================================
;; 12. 必須ユーティリティ
;; =========================================================
(use-package which-key
  :init (which-key-mode)
  :config (setq which-key-idle-delay 0.3))

(use-package helpful
  :bind
  (("C-h f" . helpful-callable)
   ("C-h v" . helpful-variable)
   ("C-h k" . helpful-key)
   ("C-h x" . helpful-command)))

;; =========================================================
;; 13. カスタム関数
;; =========================================================
(defun my/duplicate-line ()
  "現在行を複製して次の行に挿入する。"
  (interactive)
  (let ((text (buffer-substring-no-properties
               (line-beginning-position)
               (line-end-position))))
    (save-excursion
      (end-of-line)
      (newline)
      (insert text)))
  (forward-line 1))

(global-set-key (kbd "C-c d") #'my/duplicate-line)
(global-set-key (kbd "C-c c") #'comment-or-uncomment-region)

;; (リーダーキー体系は未使用)

;; =========================================================
;; 15. custom.el の分離
;; =========================================================
;; Emacs の Custom UI (M-x customize) で変更した設定を
;; init.el に書き込ませず、別ファイルに分離する。
;; これにより init.el の Git diff が汚れるのを防ぐ。
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file :noerror :nomessage))

(provide 'init-core)
;;; init-core.el ends here
