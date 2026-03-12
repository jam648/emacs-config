;;; init-debug.el --- Debug Tools & Package Management Helpers -*- lexical-binding: t -*-

;; =========================================================
;; 1. デバッグモード
;; =========================================================

(defvar my/debug-mode nil
  "Non-nil の場合、詳細なデバッグログを出力する。")

(defun my/toggle-debug-mode ()
  "デバッグモードのON/OFFを切り替える。
ON にすると use-package の詳細ログ、メッセージバッファへの警告出力が有効になる。"
  (interactive)
  (setq my/debug-mode (not my/debug-mode))
  (setq use-package-verbose my/debug-mode)
  (setq warning-minimum-level (if my/debug-mode :debug :warning))
  (message "Debug mode: %s" (if my/debug-mode "ON" "OFF"))
  
  (when my/debug-mode
    (message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    (message "Debug mode ENABLED")
    (message "  - use-package-verbose: t")
    (message "  - warning-minimum-level: :debug")
    (message "  - Check *Messages* and *Warnings* buffers")
    (message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")))

;; =========================================================
;; 2. パッケージ管理ヘルパー
;; =========================================================

(defvar my/optional-packages
  '(denote
    consult-denote
    consult-org-roam
    aider
    forge
    vterm
    vterm-toggle
    dape)
  "オプションパッケージのリスト。
これらは存在しなくても Emacs 起動は継続する。")

(defun my/list-missing-packages ()
  "インストールされていないパッケージのリストを返す。"
  (let ((missing '()))
    (dolist (pkg my/optional-packages)
      (unless (or (package-installed-p pkg)
                  (locate-library (symbol-name pkg)))
        (push pkg missing)))
    (nreverse missing)))

(defun my/show-missing-packages ()
  "起動時に不足パッケージを一覧表示する。"
  (interactive)
  (let ((missing (my/list-missing-packages)))
    (if missing
        (progn
          (message "⚠️ 以下のオプションパッケージがインストールされていません:")
          (dolist (pkg missing)
            (message "  - %s" pkg))
          (message "M-x my/install-missing-packages で一括インストールできます。"))
      (message "✓ すべてのオプションパッケージがインストール済みです。"))))

(defun my/install-missing-packages ()
  "不足しているパッケージを一括インストールする。"
  (interactive)
  (let ((missing (my/list-missing-packages)))
    (if (null missing)
        (message "✓ すべてのパッケージがインストール済みです。")
      (when (yes-or-no-p
             (format "%d 個のパッケージをインストールしますか？ (%s)"
                     (length missing)
                     (mapconcat #'symbol-name missing ", ")))
        (package-refresh-contents)
        (dolist (pkg missing)
          (message "Installing %s..." pkg)
          (condition-case err
              (package-install pkg)
            (error
             (message "⚠️ %s のインストールに失敗: %s"
                      pkg (error-message-string err)))))
        (message "✓ パッケージのインストールが完了しました。")))))

;; 起動時に不足パッケージを通知
(add-hook 'emacs-startup-hook #'my/show-missing-packages)

;; =========================================================
;; 3. 起動ログ表示
;; =========================================================

(defun my/show-startup-log ()
  "起動ログバッファを表示する。"
  (interactive)
  (if (get-buffer my/startup-log-buffer)
      (pop-to-buffer my/startup-log-buffer)
    (message "起動ログバッファが見つかりません。")))

;; =========================================================
;; 4. プロファイリング支援
;; =========================================================

(defun my/measure-startup-time ()
  "起動時間を詳細に測定して表示する。"
  (interactive)
  (message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  (message "Emacs Startup Profile")
  (message "  Init time: %s" (emacs-init-time))
  (message "  GC count: %d" gcs-done)
  (message "  GC time: %.2f sec" gc-elapsed)
  (message "  Packages: %d loaded" (length package-activated-list))
  (when (boundp 'my/init-error-log)
    (message "  Errors: %d" (length my/init-error-log)))
  (message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"))

;; =========================================================
;; 5. エラーログ表示
;; =========================================================

(defun my/show-init-errors ()
  "起動時のエラーログを専用バッファに表示する。"
  (interactive)
  (if (and (boundp 'my/init-error-log) my/init-error-log)
      (let ((buf (get-buffer-create "*Init Errors*")))
        (with-current-buffer buf
          (erase-buffer)
          (insert "═══════════════════════════════════════════════════\n")
          (insert "  Emacs 起動時のエラーログ\n")
          (insert "═══════════════════════════════════════════════════\n\n")
          (insert (format "Total errors: %d\n\n" (length my/init-error-log)))
          (dolist (entry my/init-error-log)
            (let ((module (car entry))
                  (err    (cdr entry)))
              (insert (format "【%s】\n" module))
              (insert (format "  Error: %s\n" (error-message-string err)))
              (insert (format "  Type: %s\n\n" (car err)))))
          (insert "─────────────────────────────────────────────────\n")
          (insert "対処方法:\n")
          (insert "  1. M-x my/toggle-debug-mode でデバッグモードを有効化\n")
          (insert "  2. Emacs を再起動して *Warnings* バッファを確認\n")
          (insert "  3. 各モジュールファイル (lisp/init-*.el) の該当箇所を確認\n")
          (goto-char (point-min)))
        (pop-to-buffer buf))
    (message "✓ 起動時のエラーはありません。")))

;; =========================================================
;; 6. キーバインド
;; =========================================================

(provide 'init-debug)
;;; init-debug.el ends here
