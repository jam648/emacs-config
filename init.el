;;; init.el --- Modular Emacs Config -*- lexical-binding: t -*-
;;
;; 堅牢さと速度を重視した分割設定のエントリポイント。
;; 各モジュールは condition-case で保護され、1つの失敗が全体に波及しない。
;; 致命的エラー時は Emergency モードで最小限の設定のみ適用する。

;; =========================================================
;; 0-A. Emergency セーフモード
;; =========================================================
(defvar my/init-emergency-mode nil
  "Non-nil の場合、Emergency モードで起動している。")

(defvar my/init-error-log nil
  "起動時に発生したエラーのリスト。")

;; init.el 全体を condition-case でラップし、致命的エラーを捕捉する
(condition-case err
    (progn

;; =========================================================
;; 0-B. 起動ログバッファの初期化
;; =========================================================
(defvar my/startup-log-buffer "*Emacs Startup Log*"
  "起動ログを記録するバッファ名。")

(defun my/log-startup (message &optional level)
  "起動ログバッファに MESSAGE を記録する。
LEVEL は 'info, 'warn, 'error のいずれか。デフォルトは 'info。"
  (let ((level (or level 'info))
        (timestamp (format-time-string "%H:%M:%S.%3N")))
    (with-current-buffer (get-buffer-create my/startup-log-buffer)
      (goto-char (point-max))
      (insert (format "[%s] %s: %s\n"
                      timestamp
                      (upcase (symbol-name level))
                      message)))))

(my/log-startup "======== Emacs 起動開始 ========")
(my/log-startup (format "Emacs version: %s" emacs-version))
(my/log-startup (format "System: %s" system-type))

;; =========================================================
;; 0-C. 起動時パフォーマンス
;; =========================================================
(setq gc-cons-threshold (* 128 1024 1024))
(setq read-process-output-max (* 1024 1024))
(setq native-comp-async-report-warnings-errors nil)
(my/log-startup "GC threshold set to 128MB")

;; =========================================================
;; 1. 秘匿情報の読み込み
;; =========================================================
(let ((secrets (locate-user-emacs-file ".secret.el")))
  (if (file-exists-p secrets)
      (progn
        (load secrets :noerror :nomessage)
        (my/log-startup (format "Loaded secrets from: %s" secrets)))
    (my/log-startup "No .secret.el found (optional)" 'warn)))

;; =========================================================
;; 2. モジュールローダー
;; =========================================================
(let ((lisp-dir (locate-user-emacs-file "lisp")))
  (unless (file-exists-p lisp-dir)
    (make-directory lisp-dir t)
    (my/log-startup (format "Created lisp directory: %s" lisp-dir)))
  (add-to-list 'load-path lisp-dir)
  (my/log-startup (format "Added to load-path: %s" lisp-dir)))

;; =========================================================
;; 3. モジュールの読み込み
;; =========================================================

(defun my/require-module (module)
  "MODULE を require し、成功/失敗をログに記録する。"
  (my/log-startup (format "Loading module: %s..." module))
  (condition-case err
      (progn
        (require module)
        (my/log-startup (format "✓ Module loaded: %s" module)))
    (error
     (my/log-startup (format "✗ Failed to load %s: %s" module (error-message-string err)) 'error)
     (push (cons module err) my/init-error-log)
     nil)))

(my/require-module 'init-core)
(my/require-module 'init-ui)
(my/require-module 'init-completion)
(my/require-module 'init-edit)
(my/require-module 'init-input)
(my/require-module 'init-notes)
(my/require-module 'init-dev)
(my/require-module 'init-ai)
(my/require-module 'init-debug)

;; =========================================================
;; 4. 起動後処理
;; =========================================================
(add-hook 'emacs-startup-hook
          (lambda ()
            (my/log-startup (format "======== 起動完了: %s | %d packages ========"
                                    (emacs-init-time)
                                    (length package-activated-list)))
            
            (when my/init-error-log
              (my/log-startup (format "⚠️ %d module(s) failed to load" (length my/init-error-log)) 'warn)
              (message "⚠️ Some modules failed to load. Check %s for details." my/startup-log-buffer))))

      ) ; progn end

  ;; =========================================================
  ;; Emergency エラーハンドラ
  ;; =========================================================
  (error
   (setq my/init-emergency-mode t)
   (setq my/init-error-log (list (cons 'init.el err)))
   
   (with-current-buffer (get-buffer-create my/startup-log-buffer)
     (erase-buffer)
     (insert "╔════════════════════════════════════════════════════════╗\n")
     (insert "║   🚨 EMERGENCY MODE: Init failed, minimal config loaded ║\n")
     (insert "╚════════════════════════════════════════════════════════╝\n\n")
     (insert (format "Error during init.el load:\n%s\n\n" (error-message-string err)))
     (insert "Emacs は最小限の設定で起動しました。\n")
     (insert "問題を解決するには:\n")
     (insert "  1. M-x view-echo-area-messages でエラー詳細を確認\n")
     (insert "  2. この buffer の内容を確認\n")
     (insert "  3. ~/.emacs.d/init.el を確認\n\n")
     (insert "一時的な対処:\n")
     (insert "  emacs -q で起動すると設定を読み込まずに起動できます。\n"))
   
   (pop-to-buffer my/startup-log-buffer)
   
   (tool-bar-mode -1)
   (menu-bar-mode -1)
   (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
   (global-display-line-numbers-mode t)
   (setq inhibit-startup-message t)
   
   (message "🚨 EMERGENCY MODE: Init failed. Check %s" my/startup-log-buffer)))

(provide 'init)
;;; init.el ends here
