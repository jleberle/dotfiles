;;; ui.el --- theme, modeline, which-key -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/plugins/ui.lua: nord.nvim -> nord-theme,
;; lualine -> doom-modeline, which-key.nvim -> which-key (the leader-menu
;; idea is native to Emacs's own package of the same name).

(use-package nord-theme
  :straight t
  :config
  (load-theme 'nord t))

(use-package which-key
  :straight t
  :init (which-key-mode 1)
  :config
  (setq which-key-idle-delay 0.3)
  ;; Names for the prefixes, so `C-c f' / `C-c p' / `C-c c' are not bare
  ;; letters -- mirrors the nvim which-key `spec' group labels.
  (which-key-add-key-based-replacements
    "C-c f" "find / citations"
    "C-c p" "pandoc / preview"
    "C-c c" "code"
    "C-c s" "surround"))

(use-package doom-modeline
  :straight t
  :init (doom-modeline-mode 1))

;; Word count for prose buffers; mirrors the nvim lualine_x segment.
(defun dotfiles/modeline-word-count ()
  (if (derived-mode-p 'markdown-mode 'text-mode)
      (format " %dw" (count-words (point-min) (point-max)))
    ""))

(add-to-list 'global-mode-string '(:eval (dotfiles/modeline-word-count)))

(provide 'ui)
