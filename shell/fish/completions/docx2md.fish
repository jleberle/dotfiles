# Completions for `docx2md`: a .docx to convert, then how to treat the
# tracked changes inside it.

complete -c docx2md -f
complete -c docx2md -n __fish_is_first_token -k -a '(__fish_complete_suffix .docx)'
complete -c docx2md -n 'not __fish_is_first_token' -a all \
    -d 'Keep tracked changes visible (default)'
complete -c docx2md -n 'not __fish_is_first_token' -a accept \
    -d 'Apply the tracked changes'
complete -c docx2md -n 'not __fish_is_first_token' -a reject \
    -d 'Discard the tracked changes'
