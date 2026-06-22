# ------------------------------------------------------------------------------
# Workflow locations  (single source of truth)
#
# Personal paths that several functions used to hardcode independently (Zotero
# library, notes trees, research archives, website repo). Centralizing them here
# means a move or a per-machine difference is one edit, not a grep-and-replace
# across functions.
#
# Each is `set -q`-guarded so a per-machine universal override
# (`set -Ux ZOTERO_LIBRARY_JSON …`) wins — without the guard, conf.d re-running
# every session would clobber it back to the default below.
# ------------------------------------------------------------------------------

# The dotfiles repo itself — used by functions that read tracked files
# (newdoc CSL/reference-doc, valeinit, mdexport, dots).
set -q DOTFILES_DIR;           or set -gx DOTFILES_DIR           $HOME/.dotfiles

set -q ZOTERO_LIBRARY_JSON;    or set -gx ZOTERO_LIBRARY_JSON    $HOME/Documents/Library/Library.json
set -q ZOTERO_LIBRARY_BIB;     or set -gx ZOTERO_LIBRARY_BIB     $HOME/Documents/Library/Library.bib
set -q READING_NOTES_DIR;      or set -gx READING_NOTES_DIR      "$HOME/Notes/02 Notes/01 Reading Notes"
set -q RESEARCH_NOTES_DIR;     or set -gx RESEARCH_NOTES_DIR     "$HOME/Notes/02 Notes/02 Research Notes"
set -q RESEARCH_ARCHIVES_DIR;  or set -gx RESEARCH_ARCHIVES_DIR  "$HOME/Notes/03 Research/Archives"
set -q WEBSITE_REPO;           or set -gx WEBSITE_REPO           $HOME/git/website
