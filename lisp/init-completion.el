;;; init-completion.el --- Completion Framework: Vertico/Consult/Corfu -*- lexical-binding: t -*-
;; [重要] このファイルは init-notes より必ず先にロードすること。
;; consult-org-roam が consult に依存するため、ロード順が守られないと起動時エラーになる。

;; =========================================================
;; 1. ミニバッファ補完 (Vertico)
;; =========================================================
(use-package vertico
  :init (vertico-mode)
  :config
  (setq vertico-cycle t)
  (setq vertico-count 15))

(use-package orderless
  :defer nil
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides
   '((file (styles basic partial-completion))
     (eglot (styles orderless)))))

(use-package marginalia
  :init (marginalia-mode))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; =========================================================
;; 2. Consult (強力な検索・ナビゲーション)
;; =========================================================
(use-package consult
  :bind
  (("C-s"   . consult-line)
   ("C-x b" . consult-buffer)
   ("M-y"   . consult-yank-pop)
   ("M-g g" . consult-goto-line)
   ("M-i"   . consult-imenu)
   ("M-s r" . consult-ripgrep)
   ("M-s f" . consult-find)
   ("M-s e" . consult-flymake))
  :config
  (setq consult-ripgrep-args
        (concat "rg --null --line-buffered --color=never "
                "--max-columns=1000 --path-separator / "
                "--smart-case --no-heading --line-number ."))
  (setq consult-preview-key '(:debounce 0.2 any)))

;; =========================================================
;; 3. Embark (コンテキストアクション)
;; =========================================================
(use-package embark
  :bind
  (("C-."   . embark-act)
   ("C-;"   . embark-dwim)
   ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; =========================================================
;; 4. インライン補完 (Corfu)
;; =========================================================
(use-package corfu
  :init (global-corfu-mode)
  :custom
  (corfu-auto        t)
  (corfu-auto-delay  0.1)
  (corfu-auto-prefix 1)
  (corfu-cycle       t)
  (corfu-preselect   'prompt)
  (tab-always-indent 'complete)
  (corfu-popupinfo-delay '(0.2 . 0.1))
  :config
  (corfu-popupinfo-mode))

(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;; =========================================================
;; 5. Cape (補完ソースの拡張)
;; =========================================================
(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  :config
  (setq cape-dabbrev-min-length 3))

(provide 'init-completion)
;;; init-completion.el ends here
