# ------------------------------------------------------------------------------
# Workflow locations  (single source of truth)
#
# The tracked values live in <repo>/paths.env so both fish and Neovim can read
# the same file without either side parsing the other's config syntax.
#
# Each export remains `set -q`-guarded so a per-machine universal override
# (`set -Ux ZOTERO_LIBRARY_JSON …`) still wins — without the guard, conf.d
# re-running every session would clobber it back to the tracked default.
# ------------------------------------------------------------------------------

set -l __dotfiles_paths_script (path resolve -- (status filename))
set -l __dotfiles_repo_dir (path normalize -- (path dirname -- $__dotfiles_paths_script)/../../..)
set -l __dotfiles_paths_file "$__dotfiles_repo_dir/paths.env"

# paths.env is tracked in the repo alongside this file, so a missing one means a
# broken checkout — there is no fallback worth carrying for that case. Only
# DOTFILES_DIR is defaulted, since it is what would point you back at the repo.
set -q DOTFILES_DIR; or set -gx DOTFILES_DIR "$__dotfiles_repo_dir"

if test -f "$__dotfiles_paths_file"
    while read -l __dotfiles_line
        set __dotfiles_line (string trim -- "$__dotfiles_line")
        if test -z "$__dotfiles_line"
            continue
        end
        if string match -qr '^#' -- "$__dotfiles_line"
            continue
        end

        set -l __dotfiles_parts (string split -m 1 '=' -- "$__dotfiles_line")
        if test (count $__dotfiles_parts) -ne 2
            continue
        end

        set -l __dotfiles_key (string trim -- $__dotfiles_parts[1])
        set -l __dotfiles_value (string trim -- $__dotfiles_parts[2])

        set -l __dotfiles_first_char (string sub -s 1 -l 1 -- "$__dotfiles_value")
        set -l __dotfiles_last_char (string sub -s -1 -l 1 -- "$__dotfiles_value")
        if test (string length -- "$__dotfiles_value") -ge 2
            if test "$__dotfiles_first_char" = '"' -a "$__dotfiles_last_char" = '"'
                set __dotfiles_value (string sub -s 2 -e -1 -- "$__dotfiles_value")
            else if test "$__dotfiles_first_char" = "'" -a "$__dotfiles_last_char" = "'"
                set __dotfiles_value (string sub -s 2 -e -1 -- "$__dotfiles_value")
            end
        end

        set __dotfiles_value (string replace -a '$HOME' $HOME -- "$__dotfiles_value")
        set __dotfiles_value (string replace -a '${HOME}' $HOME -- "$__dotfiles_value")

        set -q $__dotfiles_key; or set -gx $__dotfiles_key "$__dotfiles_value"
    end < "$__dotfiles_paths_file"
end

set -e __dotfiles_line __dotfiles_parts __dotfiles_key __dotfiles_value
set -e __dotfiles_first_char __dotfiles_last_char
set -e __dotfiles_paths_script __dotfiles_repo_dir __dotfiles_paths_file
