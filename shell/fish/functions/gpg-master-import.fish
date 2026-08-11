function gpg-master-import --description 'Import GPG master key from USB for editing'
    if __help_requested $argv
        echo "usage: gpg-master-import   (no arguments)"
        return 0
    end

    set usb /Volumes/Files
    set master_key $usb/key.asc

    if not test -d "$usb"
        echo "gpg-master-import: USB drive not mounted at $usb" >&2
        return 1
    end

    if not test -f "$master_key"
        echo "gpg-master-import: master key not found at $master_key" >&2
        return 1
    end

    gpg --import $master_key
    and echo "Master key imported. Run gpg-master-done when finished."
end
