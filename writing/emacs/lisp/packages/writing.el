;;; writing.el --- distraction-free mode + editing conveniences -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/plugins/writing.lua.

;; zen-mode.nvim (+ twilight dimming inactive code) -> olivetti, which
;; centers the body text and pads the margins. Emacs has no direct twin of
;; twilight's "dim everything but the current paragraph," so this covers the
;; centering half only; bound to `C-c z' in config/keymaps.el.
(use-package olivetti
  :straight t
  :commands olivetti-mode
  :config
  (setq olivetti-body-width 90))

;; mini.pairs -> Emacs's built-in electric-pair-mode.
(electric-pair-mode 1)

;; mini.comment's `gcc' / `gc' -> Emacs's own comment-dwim (`M-;'), already
;; bound by default; nothing to add.

;; mini.surround (`sa'/`sd'/`sr') -> embrace, the closest analog: add/change/
;; delete a pair around a region or textobject.
(use-package embrace
  :straight t
  :bind (("C-c s a" . embrace-add)
         ("C-c s d" . embrace-delete)
         ("C-c s c" . embrace-change)))

(provide 'writing)
