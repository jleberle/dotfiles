function valeinit --description 'Scaffold a per-project .vale.ini from the dotfiles template'
    # usage: valeinit   (run in the project root)
    # A project-local .vale.ini overrides the global ~/.vale.ini that
    # `make vale` installs (nvim-lint picks whichever is nearest).
    if __help_requested $argv
        echo "usage: valeinit   (run in the project root)"
        return 0
    end

    if test -e .vale.ini
        echo "valeinit: .vale.ini already exists here" >&2
        return 1
    end

    # The cp used to be unchecked, with the success message printed
    # unconditionally after it — so an unset DOTFILES_DIR produced cp's usage
    # text, "Wrote .vale.ini", exit 0, no file, and a stray .vale/styles.
    set -l template "$DOTFILES_DIR/writing/vale/vale-project.ini"
    __need_path valeinit file "vale project template" "$template"; or return 1

    cp "$template" .vale.ini; or return 1
    mkdir -p .vale/styles
    echo "Wrote .vale.ini (StylesPath: .vale/styles)"
    echo "Edit BasedOnStyles to taste; run 'vale sync' if you add Packages."
end
