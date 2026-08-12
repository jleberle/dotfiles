;;; markdown-cfg.el --- prose authoring -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/plugins/markdown.lua (render-markdown.nvim).
;; File is named markdown-cfg.el, not markdown.el, so its `provide' doesn't
;; collide with the markdown-mode package's own `markdown' feature.

(use-package markdown-mode
  :straight t
  :mode ("\\.md\\'" . markdown-mode)   ; ft = "markdown" in the nvim config
  :config
  (setq markdown-hide-markup t                    ; conceallevel = 2
        markdown-fontify-code-blocks-natively t))  ; code.width = "block"

;; render-markdown.nvim also renders table borders/alignment; valign is the
;; closest package-level analog for that piece.
(use-package valign
  :straight t
  :hook (markdown-mode . valign-mode))

;; No analog needed for render-markdown's `latex.enabled = false': that nvim
;; setting exists only to silence a "missing latex parser" notice, and
;; markdown-mode doesn't fontify LaTeX unless a math package is added, so
;; there's nothing to turn off here.

(provide 'markdown-cfg)
