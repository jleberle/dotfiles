;;; keymaps.el --- global key mappings -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/config/keymaps.lua. Emacs isn't modal, so a bare
;; "," leader (nvim's mapleader) would swallow every comma typed in prose.
;; `C-c` is the prefix Emacs itself reserves for user bindings, so it plays
;; leader's role here; the letters after it mirror nvim's <leader> table
;; one-for-one (`C-c w` <-> `<leader>w`, `C-c f f` <-> `<leader>ff`, ...) so
;; the muscle memory carries over even though the trigger key doesn't. See
;; docs/emacs.md for the full table, including the two nvim mappings
;; (`<leader>e`, `-` for Oil) that have no `C-c` twin because Emacs already
;; has a shorter built-in path (`M-x eldoc`, `C-x C-j').

(require 'paths)

(global-set-key (kbd "C-c w") #'save-buffer)
(global-set-key (kbd "C-c q") #'quit-window)

(global-set-key (kbd "C-c f f") #'find-file)
(global-set-key (kbd "C-c f g") #'consult-ripgrep)
(global-set-key (kbd "C-c f b") #'consult-buffer)

(defun dotfiles/open-citation-in-zotero ()
  "Jump from the @citekey nearest point to its item in Zotero.
Better BibTeX registers the zotero://select URL handler and resolves
@citekey form directly; companion to `citar-insert-citation', which
inserts these keys. Simplified port of the nvim <leader>fo mapping: that
version resolves the exact WORD under the cursor, this one takes the
nearest @key on the current line, which covers the common case of one
citation per line/bracket."
  (interactive)
  (let ((line (thing-at-point 'line t)))
    (if (and line (string-match "@\\([[:alnum:]_.:#$%&+?<>~/-]+\\)" line))
        (browse-url (concat "zotero://select/items/@" (match-string 1 line)))
      (message "No @citekey on this line"))))

(global-set-key (kbd "C-c f o") #'dotfiles/open-citation-in-zotero)

;; Zen mode (olivetti-mode; packages/writing.el)
(global-set-key (kbd "C-c z") #'olivetti-mode)

;; Oil's "edit-the-directory-as-a-buffer" browser has no rebinding here --
;; dired-jump (`C-x C-j', built-in) is the direct equivalent, and a bare `-'
;; can't be repurposed globally without breaking every literal minus sign.

;; Conform's manual format trigger (apheleia; packages/lsp.el)
(global-set-key (kbd "C-c c f") #'apheleia-format-buffer)

;; Pandoc exports with citation + cross-reference processing. The pipeline
;; (crossref filter ordering, citeproc) lives in writing/pandoc/defaults.yaml,
;; shared with the fish mdexport function and the nvim <leader>p mappings.
;; Runs asynchronously so Emacs stays responsive during slow PDF/LaTeX
;; builds; reports pandoc's stderr warnings even on a zero-exit run, since an
;; unresolved citekey exports "successfully" with `smith2020?' left in the
;; text. Runs from the document's own directory so relative paths in
;; metadata.yaml and relative images resolve.
(defvar dotfiles/pandoc-defaults
  (expand-file-name "writing/pandoc/defaults.yaml" (dotfiles/dotfiles-dir)))

(defun dotfiles/pandoc-export (ext)
  (when (buffer-modified-p) (save-buffer))
  (let* ((dir (file-name-directory (buffer-file-name)))
         (file (file-name-nondirectory (buffer-file-name)))
         (output (concat (file-name-base file) "." ext))
         (metadata (expand-file-name "metadata.yaml" dir))
         (cmd (append (list "pandoc" "-d" dotfiles/pandoc-defaults file "-o" output)
                      (when (file-readable-p metadata)
                        (list (concat "--metadata-file=" metadata)))))
         (default-directory dir)
         (err-buf (generate-new-buffer " *pandoc-export*")))
    (message "Exporting %s …" output)
    (make-process
     :name "pandoc-export"
     :command cmd
     :buffer nil
     :stderr err-buf
     :sentinel
     (lambda (proc _event)
       (unless (process-live-p proc)
         (let ((warnings (string-trim (with-current-buffer err-buf (buffer-string))))
               (status (process-exit-status proc)))
           (kill-buffer err-buf)
           (cond
            ((not (zerop status))
             (message "pandoc failed:\n%s" warnings))
            ((not (string-empty-p warnings))
             (message "Exported %s, with warnings:\n%s" output warnings))
            (t
             (message "Exported %s" output)))))))))

(global-set-key (kbd "C-c p h") (lambda () (interactive) (dotfiles/pandoc-export "html")))
(global-set-key (kbd "C-c p p") (lambda () (interactive) (dotfiles/pandoc-export "pdf")))
(global-set-key (kbd "C-c p d") (lambda () (interactive) (dotfiles/pandoc-export "docx")))

(defun dotfiles/preview-in-marked ()
  "Live preview in Marked 2 (re-renders on every save)."
  (interactive)
  (when (buffer-modified-p) (save-buffer))
  (start-process "marked-preview" nil "open" "-a" "Marked 2" (buffer-file-name)))

(global-set-key (kbd "C-c p v") #'dotfiles/preview-in-marked)

;; Citation picker (citar; packages/citations.el)
(global-set-key (kbd "C-c f c") #'citar-insert-citation)

;; Magit (packages/editor.el) -- no nvim <leader> equivalent to mirror;
;; C-c g is free, and magit-status's own transient covers everything else.
(global-set-key (kbd "C-c g") #'magit-status)

;; On-demand completion popup (corfu; packages/completion.el) -- the
;; <C-space> equivalent. Not bound to C-SPC itself: that key is
;; set-mark-command everywhere in Emacs, and shadowing it breaks selection.
(global-set-key (kbd "C-c TAB") #'completion-at-point)

(provide 'keymaps)
