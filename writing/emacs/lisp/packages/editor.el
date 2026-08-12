;;; editor.el --- navigation, search, syntax, git gutter -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/plugins/editor.lua.

;; Oil.nvim's "edit-the-directory-as-a-buffer" model is dired's native
;; paradigm -- nothing to install. `C-x C-j' (dired-jump, built-in) opens the
;; current file's directory, the Oil equivalent of nvim's `-' mapping; see
;; config/keymaps.el for why `-' itself isn't rebound.
(use-package dired
  :straight nil
  :config
  (setq dired-listing-switches "-alh"
        dired-dwim-target t))

;; Telescope's fuzzy pickers -> vertico + orderless + marginalia + consult,
;; the closest modern analog: minibuffer completion with fuzzy matching and
;; rich annotations, rather than a separate popup UI.
(use-package vertico
  :straight t
  :init (vertico-mode 1))

(use-package orderless
  :straight t
  :init
  (setq completion-styles '(orderless basic)
        completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :straight t
  :init (marginalia-mode 1))

(use-package consult
  :straight t)

;; undofile -> undo-fu-session, the closest package-level analog: persists
;; undo history to disk per-buffer across Emacs restarts.
(use-package undo-fu-session
  :straight t
  :init (undo-fu-session-global-mode 1))

;; nvim-treesitter -> Emacs's built-in tree-sitter (29+), with treesit-auto
;; remapping the -ts-mode variants onto the plain major modes automatically
;; and installing missing grammars, mirroring nvim-treesitter's own
;; install-on-demand behavior.
(use-package treesit-auto
  :straight t
  :config
  (setq treesit-auto-install 'prompt)
  (global-treesit-auto-mode 1))

;; gitsigns.nvim -> diff-hl: fringe markers for added/changed/removed lines.
(use-package diff-hl
  :straight t
  :init (global-diff-hl-mode 1))

;; No nvim counterpart -- writing/nvim has no full git porcelain, only
;; gitsigns' gutter. Magit is a genuine Emacs-only addition, not a port;
;; magit-status (C-c g; see keymaps.el) opens its own transient menus, so
;; nothing beyond that one binding is needed.
(use-package magit
  :straight t)

(provide 'editor)
