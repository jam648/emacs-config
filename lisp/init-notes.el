;;; init-notes.el --- Notes & Writing: Org, Denote, Org-roam, Writeroom -*- lexical-binding: t -*-
;; [依存] init-completion.el が先にロードされている必要がある (consult-org-roam)

;; =========================================================
;; 1. Org-mode 基本設定
;; =========================================================
(use-package org
  :ensure nil
  :hook
  ((org-mode . org-indent-mode)
   (org-mode . visual-line-mode)
   (org-mode . smartparens-mode))
  :config
  (setq org-directory (expand-file-name "~/Documents/org/"))
  (unless (file-exists-p org-directory)
    (make-directory org-directory t))

  (setq org-hide-emphasis-markers      t)
  (setq org-startup-with-inline-images t)
  (setq org-startup-indented           t)
  (setq org-startup-folded             nil)
  (setq org-image-actual-width         400)

  (setq org-src-fontify-natively         t)
  (setq org-src-tab-acts-natively        t)
  (setq org-edit-src-content-indentation 0)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "DOING(d)" "WAITING(w)" "|" "DONE(D)" "CANCELED(c)")))

  (setq org-log-done        'time)
  (setq org-log-into-drawer  t)

  (setq org-todo-keyword-faces
        '(("TODO"     . (:inherit error   :weight bold))
          ("DOING"    . (:inherit warning :weight bold))
          ("WAITING"  . (:inherit warning :weight bold :slant italic))
          ("DONE"     . (:inherit success :weight bold))
          ("CANCELED" . (:inherit shadow  :weight bold))))

  (setq org-export-with-smart-quotes     t)
  (setq org-export-with-sub-superscripts nil)

  (setq org-agenda-files (list org-directory))
  (setq org-agenda-span  'week)

  (setq-default fill-column 80))

;; =========================================================
;; 2. Org-modern (見出し・表のビジュアル強化)
;; =========================================================
;; org-modern-checkbox の型は (char . string) の alist。
;; t を設定すると "Wrong type argument: sequencep, t" が発生するため明示的に指定する。
(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :config
  ;; 見出し記号 (list 型: 正しい)
  (setq org-modern-star '("◉" "○" "◈" "◇" "✳" "◆"))

  ;; テーブルの視覚強化 (boolean 型: 正しい)
  (setq org-modern-table t)

  ;; org-modern-checkbox: (char . string) の alist 型。t を指定しないこと。
  (setq org-modern-checkbox
        '((?X  . "☑")    ; [X] 完了済み
          (?-  . "◐")    ; [-] 中間状態
          (?\s . "☐")))  ; [ ] 未チェック

  ;; org-modern-tag / priority / todo はデフォルト t のため設定不要
  )

;; =========================================================
;; 3. Denote (ファイル名ベースの知識管理 by Prot)
;; =========================================================
;; C-c d は init-core.el の my/duplicate-line に使用済みのため C-c n を使用。
;; denote-directory は :init で即時設定 (:config では遅延ロード時まで未設定になる)。
(use-package denote
  :init
  ;; :init で設定することで、遅延ロード前でも変数を参照可能にする
  (setq denote-directory
        (expand-file-name "~/Documents/org/denote/"))

  :config
  ;; ディレクトリが存在しない場合は作成
  (unless (file-exists-p denote-directory)
    (make-directory denote-directory t))

  ;; デフォルトファイル形式 (org 推奨)
  (setq denote-file-type 'org)

  ;; ファイル名のコンポーネント (日付・キーワード・シグネチャ・タイトル)
  (setq denote-prompts '(title keywords))

  ;; org-mode バッファで Denote リンクの補完を有効化
  (with-eval-after-load 'org
    (require 'denote-org-extras nil :noerror))

  ;; Dired との連携 (ファイルを選択して rename / link 操作)
  (with-eval-after-load 'dired
    (require 'denote-dired nil :noerror)
    (add-hook 'dired-mode-hook #'denote-dired-mode-in-directories))

  ;; Denote の対象ディレクトリを Dired でも色付け
  (setq denote-dired-directories (list denote-directory))

  ;; consult-denote: consult を使った Denote ノート検索
  ;; locate-library で存在確認してから require する
  (with-eval-after-load 'consult
    (when (locate-library "consult-denote")
      (condition-case err
          (progn
            (require 'consult-denote)
            (consult-denote-mode 1))
        (error
         (message "⚠️ consult-denote の読み込みに失敗: %s"
                  (error-message-string err))))))

  :bind
  ;; C-c d は my/duplicate-line に使用済みのため C-c n を使用
  (("C-c n n" . denote)                  ; 新規ノート作成
   ("C-c n f" . denote-open-or-create)   ; ノートを開く or 作成
   ("C-c n l" . denote-link)             ; 現在ノートにリンク挿入
   ("C-c n b" . denote-backlinks)        ; バックリンク一覧
   ("C-c n r" . denote-rename-file)      ; ファイル名の整合性リネーム
   ("C-c n k" . denote-keywords-add)     ; キーワード追加
   ("C-c n s" . consult-denote-find)))   ; consult でノード検索

;; =========================================================
;; 4. Org-roam (DB ベースの知識グラフ管理)
;; =========================================================
;; org-roam-directory は :init で即時設定 (:custom や :config では過延ロード時まで未設定)。
(use-package org-roam
  :init
  ;; :init で設定することで、過延ロード前でも変数を参照可能にする
  (setq org-roam-directory (file-truename "~/Documents/org-roam/"))

  :config
  (unless (file-exists-p org-roam-directory)
    (make-directory org-roam-directory t))

  ;; DB 初期化失敗時のエラーハンドリング
  ;; SQLite がない環境や権限エラーで DB 作成に失敗すると無限ループになるため、
  ;; condition-case で捕捉し、失敗しても Emacs 起動自体は継続させる。
  (condition-case err
      (org-roam-db-autosync-mode)
    (error
     (message "⚠️ org-roam DB の初期化に失敗しました: %s" (error-message-string err))
     (message "   → SQLite3 がインストールされているか確認してください。")
     (message "   → M-x org-roam-db-sync で手動同期を試してください。")))

  (setq org-roam-capture-templates
        '(("d" "default" plain
           "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n")
           :unnarrowed t)
          ("l" "literature" plain
           "* Source\n%?\n\n* Notes\n\n* Summary\n"
           :target (file+head "literature/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+roam_tags: literature\n")
           :unnarrowed t)
          ("p" "permanent" plain
           "* Idea\n%?\n\n* References\n"
           :target (file+head "permanent/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+roam_tags: permanent\n")
           :unnarrowed t)))

  :bind
  (("C-c r f" . org-roam-node-find)
   ("C-c r i" . org-roam-node-insert)
   ("C-c r c" . org-roam-capture)
   ("C-c r g" . org-roam-graph)
   ("C-c r l" . org-roam-buffer-toggle)
   :map org-mode-map
   ("C-M-i"   . completion-at-point)))

;; =========================================================
;; 5. consult-org-roam (Consult 統合)
;; =========================================================
(use-package consult-org-roam
  :after (consult org-roam)
  :init
  (consult-org-roam-mode 1)
  :custom
  (consult-org-roam-grep-func #'consult-ripgrep)
  :bind
  (("C-c r s" . consult-org-roam-search)
   ("C-c r F" . consult-org-roam-file-find)
   ("C-c r b" . consult-org-roam-backlinks)))

;; =========================================================
;; 6. Org-pomodoro (ポモドーロタイマー)
;; =========================================================
(use-package org-pomodoro
  :after org
  :bind (:map org-mode-map
              ("C-c C-p" . org-pomodoro))
  :config
  (setq org-pomodoro-length             25)
  (setq org-pomodoro-short-break-length  5)
  (setq org-pomodoro-long-break-length  20))

;; =========================================================
;; 7. 執筆・集中モード
;; =========================================================
(use-package writeroom-mode
  :bind ("M-z" . writeroom-mode)
  :config
  (setq writeroom-width             100)
  (setq writeroom-fullscreen-effect 'maximized)
  (setq writeroom-mode-line          t))

(use-package olivetti
  :bind ("C-c o" . olivetti-mode)
  :config
  (setq olivetti-body-width 80))

;; =========================================================
;; 8. ox-pandoc (Pandoc 経由で Word・PDF 出力)
;; =========================================================
(use-package ox-pandoc
  :after org
  :if (executable-find "pandoc")
  :config
  (setq org-pandoc-options-for-docx     '((standalone . t)))
  (setq org-pandoc-options-for-pdf      '((pdf-engine . "xelatex")))
  (setq org-pandoc-options-for-markdown '((standalone . t))))

;; =========================================================
;; 9. Markdown
;; =========================================================
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"       . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :config
  (setq markdown-fontify-code-blocks-natively t)
  (setq markdown-command "pandoc"))

(provide 'init-notes)
;;; init-notes.el ends here
