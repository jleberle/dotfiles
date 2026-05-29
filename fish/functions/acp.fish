function acp --description 'All-in-one Git: add, signed commit, push'
    # usage: acp <commit message>   (quotes optional)
    if test (count $argv) -eq 0
        echo "usage: acp <commit message>" >&2
        return 1
    end

    git add . \
        && git commit -S -m "$argv" \
        && git push
end
