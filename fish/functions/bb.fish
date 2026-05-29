function bb --description 'Launch BBEdit; dir arg opens and cds; file arg opens'
    if test (count $argv) -eq 0
        bbedit --launch
    else
        bbedit $argv[1]
        test -d $argv[1]; and cd $argv[1]
    end
end
