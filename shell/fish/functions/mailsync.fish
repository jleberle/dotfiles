function mailsync --description 'Sync mail from Proton Bridge and update notmuch index'
    if __help_requested $argv
        echo "usage: mailsync   (no arguments)"
        return 0
    end

    __require mailsync mbsync notmuch; or return 1

    mbsync -a && notmuch new
end
