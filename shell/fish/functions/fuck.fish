function fuck --description 'Re-run the previous command under sudo'
    # $history[1] is the most recent command line in an interactive session.
    sudo fish -c "$history[1]"
end
