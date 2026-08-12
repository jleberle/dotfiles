;;; paths.el --- workflow locations shared with fish/nvim -*- lexical-binding: t; -*-

;; paths.env is the single source of truth for workflow locations, but only
;; fish (shell/fish/conf.d/paths.fish) parses it; this module just reads the
;; env vars that file exported -- real values whenever Emacs is launched from
;; a fish shell (or a GUI launch that inherits the login session's
;; environment). Each getter carries a fallback for the rare launch with
;; neither. Mirrors writing/nvim/lua/config/paths.lua.

(defun dotfiles/zotero-library-bib ()
  (let ((value (getenv "ZOTERO_LIBRARY_BIB")))
    (if (and value (not (string-empty-p value)))
        (expand-file-name value)
      (expand-file-name "~/Documents/Library/Library.bib"))))

;; DOTFILES_DIR falls back to this file's own location: `make emacs` symlinks
;; ~/.config/emacs to <repo>/writing/emacs, so resolving load-file-name finds
;; the repo even with no environment at all -- the same trick paths.lua plays
;; via stdpath("config").
(defun dotfiles/dotfiles-dir ()
  (let ((value (getenv "DOTFILES_DIR")))
    (if (and value (not (string-empty-p value)))
        value
      (let* ((config-dir (directory-file-name (file-truename user-emacs-directory)))
             (writing-dir (directory-file-name (file-name-directory config-dir))))
        (directory-file-name (file-name-directory writing-dir))))))

(provide 'paths)
