function mailsync --description 'Sync mail from mailbox.org and update notmuch index'
    mbsync -a && notmuch new
end
