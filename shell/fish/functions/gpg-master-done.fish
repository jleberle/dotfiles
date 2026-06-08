function gpg-master-done --description 'Remove GPG master key and reimport machine-specific subkeys only'
    set fingerprint 17904CDD2FA1441662D0CCD1E0646B558C79DB58
    set usb /Volumes/Files
    set machine (scutil --get LocalHostName)

    switch $machine
        case Leia
            set subkeys_file $usb/subkeys-leia.gpg
            set subkey_ids 55B2115A! 2F17E066! 533BAA7D!
        case Ahsoka
            set subkeys_file $usb/subkeys-ahsoka.gpg
            set subkey_ids 4BD1A809! 2F17E066! 533BAA7D!
        case '*'
            echo "Error: unknown machine '$machine' — add it to gpg-master-done" >&2
            return 1
    end

    if not test -f $subkeys_file
        echo "Error: subkeys not found at $subkeys_file" >&2
        return 1
    end

    # Export a fresh copy of this machine's subkeys before wiping
    echo "Exporting subkeys for $machine..."
    gpg --export-secret-subkeys $subkey_ids > /tmp/subkeys-$machine.gpg
    or return 1

    # Wipe entire keyring entry
    echo "Deleting all secret and public key material..."
    gpg --batch --yes --delete-secret-and-public-key $fingerprint
    or return 1

    # Reimport public key and machine-specific subkeys
    echo "Reimporting public key..."
    gpg --import $usb/key.asc
    or return 1

    echo "Reimporting subkeys for $machine..."
    gpg --import /tmp/subkeys-$machine.gpg
    or return 1

    # Cleanup temp file
    rm /tmp/subkeys-$machine.gpg

    # Verify
    echo ""
    echo "Verifying — sec# confirms master is offline:"
    gpg --list-secret-keys $fingerprint
end
