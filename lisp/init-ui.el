;;; init-ui.el --- Visuals: Themes, Effects, Modeline, Dashboard -*- lexical-binding: t -*-

;; =========================================================
;; 1. テーマ (Modus Themes by Prot)
;; =========================================================
;; 見出しカラーは modus-themes-headings でスタイルのみ制御する。
;; (modus-themes-with-colors 内でのパレット変数参照は避けること)

(use-package modus-themes
  :defer nil
  :config
  ;; ── 基本スタイル設定 ───────────────────────────────────
  (setq modus-themes-bold-constructs   t)
  (setq modus-themes-italic-constructs t)
  (setq modus-themes-mixed-fonts       t)
  (setq modus-themes-org-blocks        'gray-background)

  ;; ── 見出しスタイル ──────────────────────────────────────
  (setq modus-themes-headings
        '((1 . (bold 1.3))
          (2 . (bold 1.2))
          (3 . (bold 1.1))
          (t . (semilight 1.0))))

  ;; ── テーマ適用 ────────────────────────────────────────
  (load-theme 'modus-vivendi t)

  ;; ── トグル関数 ────────────────────────────────────────
  (defun my/toggle-modus-theme ()
    "Modus Vivendi (dark) と Modus Operandi (light) をトグル切替する。"
    (interactive)
    (if (eq (car custom-enabled-themes) 'modus-vivendi)
        (modus-themes-load-theme 'modus-operandi)
      (modus-themes-load-theme 'modus-vivendi))
    (message "Theme: %s" (car custom-enabled-themes)))

  :bind ("<f5>" . my/toggle-modus-theme))

;; =========================================================
;; 2. Pulsar (カーソルジャンプ時の行ハイライト by Prot)
;; =========================================================
(use-package pulsar
  :config
  (setq pulsar-pulse      t)
  (setq pulsar-delay      0.055)
  (setq pulsar-iterations 10)
  (setq pulsar-face       'pulsar-magenta)

  (setq pulsar-pulse-functions
        '(recenter-top-bottom
          move-to-window-line-top-bottom
          reposition-window
          bookmark-jump
          other-window
          delete-window
          delete-other-windows
          forward-page
          backward-page
          scroll-up-command
          scroll-down-command
          windmove-right
          windmove-left
          windmove-up
          windmove-down
          org-next-visible-heading
          org-previous-visible-heading
          org-forward-heading-same-level
          org-backward-heading-same-level
          outline-backward-same-level
          outline-forward-same-level
          outline-up-heading
          ace-window
          avy-goto-char
          avy-goto-line
          consult-line
          consult-imenu
          consult-buffer))

  (pulsar-global-mode 1))

;; =========================================================
;; 3. Beacon (スクロール後のカーソル位置フラッシュ)
;; =========================================================
(use-package beacon
  :config
  (beacon-mode 1)
  (setq beacon-blink-when-window-scrolls         t)
  (setq beacon-blink-when-point-moves-vertically 10)
  (setq beacon-size  20)
  (setq beacon-color 0.5))

;; =========================================================
;; 4. Dimmer (非アクティブウィンドウを薄暗く)
;; =========================================================
(use-package dimmer
  :config
  (setq dimmer-fraction        0.25)
  (setq dimmer-adjustment-mode :foreground) ; Modus-themes で最も安定
  (setq dimmer-use-colorspace  :rgb)

  (defun my/dimmer-prevent-p ()
    "Dimming を無効にする条件を判定する。"
    (or (not (stringp (buffer-name)))
        (member major-mode
                '(dashboard-mode
                  minibuffer-mode
                  which-key-mode
                  treemacs-mode))))

  (setq dimmer-prevent-dimming-predicates '(my/dimmer-prevent-p))

  (dimmer-configure-which-key)
  (dimmer-configure-org)
  (dimmer-configure-magit)
  (when (fboundp 'dimmer-configure-hydra)
    (dimmer-configure-hydra))

  ;; dimmer-mode を直接渡すと toggle になるため lambda で明示的に有効化
  (run-with-idle-timer 0.5 nil (lambda () (dimmer-mode 1))))

;; =========================================================
;; 5. Goggles (編集操作の視覚的フィードバック)
;; =========================================================
(use-package goggles
  :hook ((prog-mode . goggles-mode)
         (text-mode . goggles-mode))
  :config
  (setq-default goggles-pulse t))

;; =========================================================
;; 6. Anzu (検索・置換ヒット数の可視化)
;; =========================================================
(use-package anzu
  :init (global-anzu-mode +1)
  :config
  (setq anzu-mode-lighter            "")
  (setq anzu-search-threshold        1000)
  (setq anzu-replace-threshold       100)
  (setq anzu-replace-to-string-separator " → ")
  :bind (([remap query-replace]        . anzu-query-replace)
         ([remap query-replace-regexp] . anzu-query-replace-regexp)))

;; =========================================================
;; 7. Rainbow Delimiters & Rainbow Mode
;; =========================================================
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package rainbow-mode
  :hook (prog-mode . rainbow-mode))

;; =========================================================
;; 8. Nyan Mode (かわいい進捗バー)
;; =========================================================
(use-package nyan-mode
  :config
  (nyan-mode 1)
  (setq nyan-wavy-trail      t)
  (setq nyan-animate-nyancat t))

;; =========================================================
;; 9. Hide Mode Line
;; =========================================================
(use-package hide-mode-line
  :hook ((treemacs-mode        . hide-mode-line-mode)
         (dashboard-mode       . hide-mode-line-mode)
         (vterm-mode           . hide-mode-line-mode)
         (completion-list-mode . hide-mode-line-mode)))

;; =========================================================
;; 10. Nerd Icons
;; =========================================================
(use-package nerd-icons)

;; =========================================================
;; 11. モードライン (Doom Modeline)
;; =========================================================
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height         28)
  (setq doom-modeline-bar-width       4)
  (setq doom-modeline-minor-modes     t)
  (setq doom-modeline-buffer-encoding t)
  (setq doom-modeline-vcs-max-length  20))

;; =========================================================
;; 12. Dashboard (起動画面)
;; =========================================================
(use-package dashboard
  :init
  (setq initial-buffer-choice
        (lambda () (get-buffer-create "*dashboard*")))
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-center-content    t)
  (setq dashboard-show-shortcuts    t)
  (setq dashboard-startup-banner    'logo)
  (setq dashboard-set-footer        nil)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-set-file-icons    t)
  (setq dashboard-display-icons-p   t)
  (setq dashboard-icon-type         'nerd-icons)
  (setq dashboard-items
        '((recents   . 7)
          (bookmarks . 5)
          (projects  . 5)
          (agenda    . 5))))

;; =========================================================
;; 13. インデントの可視化
;; =========================================================
(use-package highlight-indent-guides
  :hook ((python-mode    . highlight-indent-guides-mode)
         (python-ts-mode . highlight-indent-guides-mode))
  :config
  (setq highlight-indent-guides-method 'bitmap))

;; =========================================================
;; 14. Zone スクリーンセーバー (10分アイドルで発動)
;; =========================================================
(use-package zone
  :ensure nil
  :config
  (setq zone-programs
        [zone-pgm-dissolve
         zone-pgm-whack-chars
         zone-pgm-drip
         zone-pgm-putz-with-case
         zone-pgm-paragraph-spaz])
  (zone-when-idle 600)
  (message "✓ Zone screensaver: armed (idle 600s)"))

(provide 'init-ui)
;;; init-ui.el ends here
