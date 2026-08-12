;;; early-init.el --- pre-package-load setup -*- lexical-binding: t; -*-

;; Emacs's own equivalent of the fast-startup goal behind nvim's lazy.nvim
;; setup: skip package.el's own autoload/activation pass (straight.el owns
;; package management instead; see init.el) and defer GUI chrome until after
;; startup so a slow frame doesn't block loading.

(setq package-enable-at-startup nil)

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t)
