# Completions for `site`, generated from the same table it dispatches from
# (__site_registry.fish) so they cannot advertise a command that no longer
# exists. Tab-completing is the fastest way to answer "what can this do?"
# without having to remember that `site` alone prints help.

function __site_no_subcommand
    set -l tokens (commandline -opc)
    test (count $tokens) -le 1
end

function __site_subcommands
    for row in (__site_registry)
        set -l field (string split \t -- $row)
        for name in (string split '|' -- $field[1])
            printf '%s\t%s\n' $name $field[5]
        end
    end
end

complete -c site -f
complete -c site -n __site_no_subcommand -a '(__site_subcommands)'
complete -c site -n __site_no_subcommand -a 'help' -d 'Show what site can do'

# Past the subcommand, hand off to files — most commands take a path (a draft,
# a post directory, images to attach).
complete -c site -n 'not __site_no_subcommand' -F

# Flags worth surfacing, scoped to the commands that accept them.
complete -c site -n '__fish_seen_subcommand_from check preflight' -l strict -d 'Also fail on Hugo warnings'
complete -c site -n '__fish_seen_subcommand_from check preflight' -l full -d 'Run exactly what CI runs (advisories become failures)'
complete -c site -n '__fish_seen_subcommand_from ship' -l full -d 'Run the --full gate before committing'
complete -c site -n '__fish_seen_subcommand_from ship' -l yes -d 'Skip the file-list confirmation'
complete -c site -n '__fish_seen_subcommand_from new publish' -l cover -d 'Include a cover image'
complete -c site -n '__fish_seen_subcommand_from publish finishsource' -l push -d 'Ship immediately after'
complete -c site -n '__fish_seen_subcommand_from publish' -l cite -d 'Append a Works Cited section'
complete -c site -n '__fish_seen_subcommand_from archive' -l dry-run -d 'Report what would change, change nothing'
complete -c site -n '__fish_seen_subcommand_from archive' -l all -d 'Check every file, not just changed ones'
complete -c site -n '__fish_seen_subcommand_from security' -l check -d 'Verify only, change nothing'
complete -c site -n '__fish_seen_subcommand_from security' -l days -d 'Fail if expiry is closer than N days' -x
