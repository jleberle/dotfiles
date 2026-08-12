;;; autocmds.el --- filetype + focus hooks -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/config/autocmds.lua.

(dolist (hook '(markdown-mode-hook text-mode-hook))
  (add-hook hook
            (lambda ()
              (visual-line-mode 1)     ; wrap = true, linebreak = true
              (flyspell-mode 1)        ; spell = true, per-filetype
              (when (derived-mode-p 'markdown-mode)
                (markdown-toggle-markup-hiding 1))))) ; conceallevel = 2

;; Reload files changed outside Emacs (pandoc output, git ops in another tmux
;; pane) automatically. Emacs's built-in analog of nvim's manual
;; FocusGained/BufEnter -> :checktime autocmd -- no tmux `focus-events on'
;; dependency needed.
(global-auto-revert-mode 1)

(provide 'autocmds)
