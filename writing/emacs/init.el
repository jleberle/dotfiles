;;; init.el --- entry point -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name "lisp/config" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "lisp/packages" user-emacs-directory))

(require 'paths)
(require 'options)
(require 'keymaps)
(require 'autocmds)

;; `make emacs` symlinks ~/.config/emacs straight at this repo, so — unlike
;; nvim, where lazy.nvim's plugins already live under a separate XDG_DATA_HOME
;; tree by default — straight.el's default `straight-base-dir' would clone
;; every package's git repo *inside* user-emacs-directory, i.e. inside this
;; tracked repo. Redirecting it to XDG_DATA_HOME reproduces nvim's separation
;; (config in the repo, downloaded plugins outside it) instead of leaving that
;; to accident.
(setq straight-base-dir
      (expand-file-name "emacs/" (or (getenv "XDG_DATA_HOME") "~/.local/share/")))

(defvar bootstrap-version 7)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" straight-base-dir)))
  (unless (file-exists-p bootstrap-file)
    (condition-case err
        (with-current-buffer
            (url-retrieve-synchronously
             "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
             'silent 'inhibit-cookies)
          (goto-char (point-max))
          (eval-print-last-sexp))
      ;; Checked, because the first run of Emacs on a new machine is also the
      ;; most likely moment to have no network. Unchecked, a failed fetch
      ;; threw deep inside straight's own loader on the next line -- that
      ;; reads as "Emacs is broken", not as "reconnect and open it again".
      ;; Mirrors the same guard in nvim's lazy.lua bootstrap.
      (error
       (error (concat "Could not download straight.el (the plugin manager), "
                       "so no packages can load.\n"
                       "This is almost always no network connection.\n"
                       "Reconnect and start Emacs again -- nothing else is wrong.\n\n"
                       "Error: %s")
              (error-message-string err)))))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t
      use-package-always-defer nil)

;; Keeps the incidental files packages/Emacs itself write (auto-save, custom.el,
;; backups, transient history, ...) out of user-emacs-directory -- i.e. out of
;; this tracked repo -- the same way straight-base-dir above keeps downloaded
;; plugin repos out of it.
(use-package no-littering
  :straight t
  :config
  (setq custom-file (no-littering-expand-var-file-name "custom.el"))
  (load custom-file 'noerror))

(require 'ui)
(require 'editor)
(require 'completion)
(require 'lsp)
(require 'linting)
(require 'markdown-cfg)
(require 'writing)
(require 'citations)
