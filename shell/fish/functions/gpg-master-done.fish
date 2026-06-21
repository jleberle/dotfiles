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

    # Stage the export inside ~/.gnupg (already mode 0700) under a private umask,
    # not /tmp: a shared, sticky directory with a predictable filename invites a
    # symlink race that would redirect secret key material to an attacker target.
    set -l gnupghome (gpgconf --list-dirs homedir 2>/dev/null; or echo $HOME/.gnupg)
    set -l old_umask (umask)
    umask 077
    set -l subkeys_tmp (mktemp "$gnupghome/subkeys-$machine.XXXXXX")
    set -l mk_status $status
    umask $old_umask
    test $mk_status -eq 0
    or return 1

    # Run the migration; clean up the staged secret material no matter how it ends.
    __gpg-master-done-run $fingerprint $usb $subkeys_tmp $subkey_ids
    set -l rc $status
    rm -f $subkeys_tmp
    return $rc
end

function __gpg-master-done-run --description 'internal: gpg-master-done body (see wrapper for cleanup)'
    set -l fingerprint $argv[1]
    set -l usb $argv[2]
    set -l subkeys_tmp $argv[3]
    set -l subkey_ids $argv[4..]

    # Export a fresh copy of this machine's subkeys before wiping
    echo "Exporting subkeys..."
    gpg --export-secret-subkeys $subkey_ids > $subkeys_tmp
    or return 1

    # Wipe entire keyring entry
    echo "Deleting all secret and public key material..."
    gpg --batch --yes --delete-secret-and-public-key $fingerprint
    or return 1

    # Reimport public key and machine-specific subkeys
    echo "Reimporting public key..."
    gpg --import $usb/key.asc
    or return 1

    echo "Reimporting subkeys..."
    gpg --import $subkeys_tmp
    or return 1

    # Verify
    echo ""
    echo "Verifying — sec# confirms master is offline:"
    gpg --list-secret-keys $fingerprint
end
