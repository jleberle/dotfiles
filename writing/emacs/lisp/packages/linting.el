;;; linting.el --- prose style linting (vale) -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/plugins/linting.lua: nvim-lint's vale linter ->
;; a flycheck checker running the same `vale` binary.

(use-package flycheck
  :straight t
  :init (global-flycheck-mode 1)
  :config
  ;; Vale discovers .vale.ini upward from its *cwd*, not from the linted
  ;; file (which arrives on stdin) -- same caveat as the nvim-lint setup.
  ;; flycheck already runs checkers with `default-directory' bound to the
  ;; buffer's own directory, so this needs no extra cwd plumbing.
  (flycheck-define-checker vale
    "A prose linter using Vale."
    :command ("vale" "--output=line" source)
    ;; vale's `line' output format is `LINE:COL:Rule:Message' with no
    ;; filename and no severity level; every hit is reported at `warning'
    ;; here as a result. `--output=JSON' carries severity if this needs
    ;; upgrading later.
    :error-patterns
    ((warning line-start line ":" column ":" (id (one-or-more (not ":"))) ":" (message) line-end))
    :modes (markdown-mode text-mode))
  (add-to-list 'flycheck-checkers 'vale)
  (add-hook 'markdown-mode-hook (lambda () (flycheck-select-checker 'vale))))

(provide 'linting)
