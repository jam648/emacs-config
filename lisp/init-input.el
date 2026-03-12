;;; init-input.el --- Japanese Input (SKK / DDSKK) -*- lexical-binding: t -*-
;; daemon モード対応: display-graphic-p の評価を after-make-frame-functions に遅延。
;; SKK isearch の defadvice 警告を skk-isearch-mode-enable nil で抑制 (Emacs 28+)。

;; =========================================================
;; DDSKK (日本語入力)
;; =========================================================
(use-package ddskk
  :bind (("C-x C-j" . skk-mode)
         ("C-x j"   . skk-mode))
  :init
  (setq default-input-method "japanese-skk")

  ;; ── isearch 統合の警告を抑制 ─────────────
  ;;
  ;; 【症状】
  ;;   Emacs 28 以降、DDSKK の skk-isearch.el が古い `defadvice` スタイルで
  ;;   isearch-mode を乗っ取るため、起動時に以下の警告が出る:
  ;;     Warning: ad-handle-definition: 'isearch-mode' got redefined
  ;;   または Emacs 30 では:
  ;;     Warning (emacs): Removing obsolete advice: ...
  ;;
  ;; 【原因】
  ;;   skk-isearch-mode-enable が non-nil (デフォルト t) の場合、
  ;;   DDSKK は isearch と統合するために advice を登録する。
  ;;   この advice が Emacs の `advice-add` ベースの新システムと競合し警告になる。
  ;;
  ;; 【解決策】
  ;;   skk-isearch-mode-enable を nil に設定して isearch 統合を無効化する。
  ;;   通常の SKK 入力 (C-x C-j) には一切影響しない。
  ;;   isearch 中に日本語を入力したい場合は C-x C-j で手動で SKK を起動できる。
  ;;
  ;; 【:init に置く理由】
  ;;   この設定は ddskk が require される前に評価される必要がある。
  ;;   :config 内では skk-isearch.el が既にロードされていて手遅れになる場合がある。
  (setq skk-isearch-mode-enable nil)

  :config
  ;; ── 辞書設定 ──────────────────────────────────────────
  ;;
  ;; 1. ユーザー辞書を macSKK と共有する
  ;; macSKKの標準の保存先である ~/.skk-jisyo を指定します。
  (setq skk-jisyo (expand-file-name "~/.skk-jisyo"))

  ;; 2. SKKサーバー（yaskkserv2 + Google変換）を利用する
  ;; サーバーが標準辞書の検索も行うため、skk-large-jisyo の直接読み込みは原則不要になります。
  (setq skk-server-host "127.0.0.1")
  (setq skk-server-portnum 1178)

  ;; 3. サーバーのレスポンス文字コードを明示する（文字化け対策）
  (setq skk-server-coding-system 'euc-jp)

  ;; 4. 共有のプライベート辞書をメモリ上で同期・保存しやすくする設定
  (setq skk-share-private-jisyo t)

  ;; 5. サーバー未導入・未起動の環境向けフォールバック対策 (ローカル大辞書)
  ;; サーバー接続に失敗した場合は、自動的にここから大辞書が参照されます。
  (let ((jisyo-path (locate-user-emacs-file "skk-get-jisyo/SKK-JISYO.L")))
    (if (file-exists-p jisyo-path)
        (progn
          (setq skk-large-jisyo jisyo-path)
          (message "✓ SKK ローカル大辞書 (フォールバック): %s" jisyo-path))
      (message (concat "⚠️ SKK ローカル大辞書が見つかりません: %s\n"
                       "   サーバー接続失敗時に備え、M-x skk-get でのダウンロードを推奨します。\n"
                       "   (保存先: ~/.emacs.d/skk-get-jisyo/SKK-JISYO.L)")
               jisyo-path)))

  ;; ── 共通設定 (GUI/Terminal 共通) ───────────────────────
  (setq skk-egg-like-newline    t)
  (setq skk-isearch-start-mode  'latin) ; isearch に入った時の初期モード

  ;; ── Smart SKK: 環境依存の表示モード設定 ──
  ;;
  ;; 問題: emacs --daemon で起動すると init 時点では (display-graphic-p) = nil
  ;;       → SKK が常にターミナルモードで初期化される
  ;;
  ;; 解決: display-graphic-p の評価を "フレーム作成後" に遅延する。
  ;;       after-make-frame-functions フックを使い、各フレームの表示種別に
  ;;       基づいて skk 変数を動的に更新する。
  (defun my/skk-apply-display-settings (&optional frame)
    "フレームの表示種別に応じて SKK の変換候補表示設定を切り替える。
FRAME が nil の場合は selected-frame を使用する。"
    (let ((graphic (if frame
                       (display-graphic-p frame)
                     (display-graphic-p))))
      (if graphic
          ;; ── GUI モード ──────────────────────────────
          (progn
            (setq skk-show-tooltip t)
            ;; 'vertical はインライン縦表示。GUI では tooltip 優先のため nil
            (setq skk-show-inline  nil)
            (message "✓ SKK: GUI モード (tooltip)"))
        ;; ── Terminal モード ──────────────────────────
        (progn
          (setq skk-show-tooltip nil)
          ;; ★改善: t → 'vertical (DDSKK 最新推奨値・より見やすいレイアウト)
          (setq skk-show-inline  'vertical)
          (message "✓ SKK: Terminal モード (inline vertical)")))))

  ;; 初回適用: daemon でない通常起動ではこれで確定する
  (my/skk-apply-display-settings)

  ;; daemon 起動時の遅延適用: 新しいフレームが作られるたびに再評価
  ;; (GUI フレームと TUI フレームが混在する daemon 運用にも対応)
  (add-hook 'after-make-frame-functions #'my/skk-apply-display-settings)

  ;; ── ヒント機能 ────────────────────────────────────────
  (condition-case err
      (require 'skk-hint)
    (error
     (message "⚠️ skk-hint の読み込みに失敗: %s" (error-message-string err)))))

(provide 'init-input)
;;; init-input.el ends here
