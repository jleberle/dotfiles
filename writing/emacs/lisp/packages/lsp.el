;;; lsp.el --- language servers + formatting -*- lexical-binding: t; -*-

;; Mirrors writing/nvim/lua/plugins/lsp.lua.

;; eglot is Emacs's built-in minimal LSP client (29+) -- the closest analog
;; to nvim-lspconfig's thin-config-over-a-client approach, as opposed to a
;; heavier framework like lsp-mode.
(use-package eglot
  :straight nil
  :hook ((lua-mode python-mode sh-mode markdown-mode) . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs '(lua-mode . ("lua-language-server")))
  (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs '(sh-mode . ("bash-language-server" "start")))
  ;; Cross-document Markdown navigation: go-to-definition on links and
  ;; headings, link/reference completion, rename across files. Style is
  ;; vale, grammar is harper_ls, spelling is Emacs's built-in flyspell --
  ;; same division of labor as the nvim config. eglot manages one server per
  ;; buffer at a time (unlike nvim's `vim.lsp.enable`, which runs marksman
  ;; and harper_ls concurrently), so marksman is the one wired here for
  ;; navigation; run `harper_ls` standalone with `M-x eglot' in a given
  ;; buffer if grammar-checking that file matters more than navigation.
  (add-to-list 'eglot-server-programs '(markdown-mode . ("marksman" "server"))))

(use-package lua-mode :straight t)

;; conform.nvim -> apheleia: the same external formatters (stylua / black /
;; prettier), triggered manually via `C-c c f' (config/keymaps.el) rather
;; than on save, mirroring the nvim config -- conform.setup there wires
;; formatters but only <leader>cf calls conform.format.
(use-package apheleia
  :straight t
  :config
  (setf (alist-get 'lua-mode apheleia-mode-alist) '(stylua))
  (setf (alist-get 'python-mode apheleia-mode-alist) '(black))
  (setf (alist-get 'markdown-mode apheleia-mode-alist) '(prettier-markdown)))

(provide 'lsp)
