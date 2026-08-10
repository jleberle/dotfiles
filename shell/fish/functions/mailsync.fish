function mailsync --description 'Sync mail from Proton Bridge and update notmuch index'
    if __help_requested $argv
        echo "usage: mailsync   (no arguments)"
        return 0
    end

    mbsync -a && notmuch new
end
