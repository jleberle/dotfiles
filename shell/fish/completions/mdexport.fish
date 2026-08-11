# Completions for `mdexport`: a pandoc output format first, then the markdown
# files to convert. The usage string says `<html|pdf|docx|...>`; the "..." is
# the part nobody can guess, so the common formats are listed here.

complete -c mdexport -f
complete -c mdexport -n __fish_is_first_token -a docx -d 'Word document'
complete -c mdexport -n __fish_is_first_token -a pdf -d 'PDF (via LaTeX)'
complete -c mdexport -n __fish_is_first_token -a html -d 'Standalone HTML'
complete -c mdexport -n __fish_is_first_token -a odt -d 'OpenDocument text'
complete -c mdexport -n __fish_is_first_token -a epub -d 'EPUB e-book'
complete -c mdexport -n __fish_is_first_token -a latex -d 'LaTeX source'
complete -c mdexport -n __fish_is_first_token -a rtf -d 'Rich Text Format'
complete -c mdexport -n 'not __fish_is_first_token' -k -a '(__fish_complete_suffix .md)'
