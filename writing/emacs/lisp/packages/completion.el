;;; completion.el --- in-buffer completion + snippets -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/plugins/completion.lua. corfu + cape are the
;; closest analog to blink.cmp: a small in-buffer popup layered over the same
;; completion-at-point-functions Emacs already exposes for LSP/path/buffer,
;; rather than a separate completion engine.

(use-package corfu
  :straight t
  :init (global-corfu-mode 1)
  :config
  ;; Menu only on demand (`C-c TAB', see config/keymaps.el), mirrors blink's
  ;; `menu.auto_show = false' -- don't pop up on every keystroke while
  ;; writing prose.
  (setq corfu-auto nil
        ;; RET inserts a newline unless an item was explicitly selected,
        ;; matching blink's `preselect = false'.
        corfu-preselect 'prompt))

(use-package cape
  :straight t
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

;; 'snippets' source -> yasnippet, loading from this config dir's snippets/
;; (same directory convention blink uses for its own snippets source) --
;; currently the pandoc-crossref snippets ported from snippets/markdown.json.
(use-package yasnippet
  :straight t
  :init
  (setq yas-snippet-dirs (list (expand-file-name "snippets" user-emacs-directory)))
  (yas-global-mode 1))

(provide 'completion)
