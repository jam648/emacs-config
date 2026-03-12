;;; init-edit.el --- Editing Enhancements -*- lexical-binding: t -*-

;; =========================================================
;; 1. 空白文字の管理
;; =========================================================
(use-package whitespace
  :ensure nil
  :hook ((prog-mode . whitespace-mode)
         (text-mode . whitespace-mode))
  :config
  (setq whitespace-style
        '(face trailing tabs empty space-mark tab-mark)))

;; 保存前に行末の余計な空白を自動削除
(add-hook 'before-save-hook #'whitespace-cleanup)

;; =========================================================
;; 2. 括弧補完 (Smartparens)
;; =========================================================
(use-package smartparens
  :hook (prog-mode . smartparens-mode)
  :config
  (require 'smartparens-config)
  (add-hook 'org-mode-hook #'smartparens-mode))

;; =========================================================
;; 3. スニペット補完 (Yasnippet)
;; =========================================================
(use-package yasnippet
  :config (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

;; =========================================================
;; 4. コードフォーマッター (Apheleia)
;; =========================================================
(use-package apheleia
  :config
  (setf (alist-get 'python-mode    apheleia-mode-alist) 'black)
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) 'black)
  (apheleia-global-mode +1))

;; =========================================================
;; 5. 選択範囲の拡張 (Expand Region)
;; =========================================================
(use-package expand-region
  :bind ("C-=" . er/expand-region))

;; =========================================================
;; 6. 画面内ジャンプ (Avy)
;; =========================================================
(use-package avy
  :bind (("C-:"   . avy-goto-char-2)
         ("M-g l" . avy-goto-line))
  :config
  (setq avy-timeout-seconds 0.3)
  (setq avy-background      t))

;; =========================================================
;; 7. マルチカーソル (Multiple Cursors)
;; =========================================================
(use-package multiple-cursors
  :bind
  (("C-S-c C-S-c" . mc/edit-lines)
   ("C->"         . mc/mark-next-like-this)
   ("C-<"         . mc/mark-previous-like-this)
   ("C-c C-<"     . mc/mark-all-like-this)))

;; =========================================================
;; 8. 強力な Undo 履歴 (Vundo)
;; =========================================================
(use-package vundo
  :bind ("C-x u" . vundo)
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols))

;; =========================================================
;; 9. 行の移動 (Drag Stuff)
;; =========================================================
(use-package drag-stuff
  :config (drag-stuff-global-mode 1)
  :bind (("M-<up>"   . drag-stuff-up)
         ("M-<down>" . drag-stuff-down)))

;; =========================================================
;; 10. 右端インジケータ
;; =========================================================
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

(provide 'init-edit)
;;; init-edit.el ends here
