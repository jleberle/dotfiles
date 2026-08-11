# Completions for `mdlinks`: which browser's open tabs to turn into Markdown
# reference definitions. Exactly one argument, so nothing completes after it.

complete -c mdlinks -f
complete -c mdlinks -n __fish_is_first_token -a safari \
    -d 'Every open Safari tab (AppleScript)'
complete -c mdlinks -n __fish_is_first_token -a firefox \
    -d 'Every open Firefox tab (session store)'
