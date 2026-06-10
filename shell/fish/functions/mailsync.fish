function mailsync --description 'Sync mail from Proton Bridge and update notmuch index'
    mbsync -a && notmuch new
end
