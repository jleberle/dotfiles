;;; options.el --- editor options -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/config/options.lua option-for-option where Emacs
;; has a direct equivalent; see docs/emacs.md for the ones that don't map
;; cleanly (splits, undofile, shell) and why.

;; UI
(global-display-line-numbers-mode 1)   ; number = true, relativenumber = false
(setq scroll-margin 10
      hscroll-margin 8)

;; Splits: Emacs's own split-window-sensibly heuristic (right when there's
;; room, else below) approximates nvim's splitright/splitbelow; there's no
;; single variable pair that reproduces it exactly.
(setq split-height-threshold nil
      split-width-threshold 0)

;; Share the macOS system clipboard -- on by default, listed here only so the
;; intent matches nvim's explicit `clipboard = "unnamedplus"`.
(setq select-enable-clipboard t)

;; Search: case-insensitive until a capital appears (Emacs's isearch already
;; does this; case-fold-search just has to stay on).
(setq case-fold-search t)

;; Timing (which-key-idle-delay lives in packages/ui.el, alongside which-key
;; itself)
(setq idle-update-delay 0.25
      echo-keystrokes 0.3)

;; Undo persists across sessions via `undo-fu-session' (packages/editor.el);
;; mirrors nvim's `undofile`.

;; Tabs
(setq-default indent-tabs-mode nil
              tab-width 2)

;; Writing-focused. `wrap`/`linebreak` are handled per-filetype in
;; config/autocmds.el (visual-line-mode), same split as nvim: those two are
;; global there, but soft-wrapping code buffers has no upside, so this port
;; narrows it to prose on purpose.
(setq-default fill-column 80)          ; textwidth
(global-display-fill-column-indicator-mode 1) ; colorcolumn = "81" (fill-column + 1)

;; spell / flyspell are enabled per-filetype (see config/autocmds.el) so they
;; don't fire in code buffers.
(setq ispell-dictionary "en_US")

;; Personal dictionary (words added with `M-$'). Pinned to the config dir so
;; it lives in the symlinked dotfiles repo and syncs across machines -- same
;; trick as nvim's `spellfile`.
(setq ispell-personal-dictionary
      (expand-file-name "ispell/en.pws" user-emacs-directory))

;; Use a POSIX shell for shell-command / compile / process shell-outs,
;; regardless of the login shell -- guards against a non-POSIX login shell
;; (fish) breaking elisp that passes POSIX command strings. Interactive
;; `M-x shell' can still be pointed at fish explicitly, same as nvim's
;; `:terminal fish` note.
(setq shell-file-name "/bin/sh")

(provide 'options)
