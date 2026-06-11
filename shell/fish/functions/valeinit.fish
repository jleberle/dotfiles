function valeinit --description 'Scaffold a per-project .vale.ini from the dotfiles template'
    # usage: valeinit   (run in the project root)
    # A project-local .vale.ini overrides the global ~/.vale.ini that
    # `make vale` installs (nvim-lint picks whichever is nearest).
    if test -e .vale.ini
        echo "valeinit: .vale.ini already exists here" >&2
        return 1
    end

    cp ~/.dotfiles/writing/vale/vale-project.ini .vale.ini
    mkdir -p .vale/styles
    echo "Wrote .vale.ini (StylesPath: .vale/styles)"
    echo "Edit BasedOnStyles to taste; run 'vale sync' if you add Packages."
end
