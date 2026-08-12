;;; citations.el --- Zotero/BibTeX citation picker -*- lexical-binding: t; -*-

;; Mirrors telescope-bibtex.nvim (writing/nvim/lua/plugins/editor.lua):
;; citar fuzzy-finds the same Better BibTeX export and inserts a pandoc
;; @citekey. Stays on the .bib for the same reason the nvim config does --
;; citar (like telescope-bibtex) parses BibTeX syntax and can't read the CSL
;; JSON pandoc itself renders from. Bound to `C-c f c' in config/keymaps.el.

(require 'paths)

(use-package citar
  :straight t
  :config
  (setq citar-bibliography (list (dotfiles/zotero-library-bib))))

(provide 'citations)
