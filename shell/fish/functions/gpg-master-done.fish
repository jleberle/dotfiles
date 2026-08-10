function gpg-master-done --description 'Remove GPG master key and reimport machine-specific subkeys only'
    if __help_requested $argv
        echo "usage: gpg-master-done   (no arguments)"
        return 0
    end

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
            echo "gpg-master-done: unknown machine '$machine' — add it to gpg-master-done" >&2
            return 1
    end

    if not test -f $subkeys_file
        echo "gpg-master-done: subkeys not found at $subkeys_file" >&2
        return 1
    end

    # Both files are checked BEFORE anything is deleted. The keyring wipe below
    # is only survivable because key.asc can be reimported afterwards, so a
    # missing/renamed key.asc has to stop the run here, not halfway through.
    if not test -f $usb/key.asc
        echo "gpg-master-done: public key not found at $usb/key.asc" >&2
        echo "                 refusing to delete local key material without it" >&2
        return 1
    end

    # Never run this unattended: it destroys local key material and the only
    # recovery path is the offline master.
    if not status --is-interactive
        echo "gpg-master-done: refusing to run non-interactively" >&2
        return 1
    end

    echo "About to DELETE all local secret and public key material for:"
    echo "  $fingerprint"
    echo "then reimport $usb/key.asc plus this machine's subkeys ($machine)."
    read -l -P "Continue? [y/N] " reply
    if not contains -- "$reply" y Y
        echo "aborted" >&2
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

    # Re-check immediately before the point of no return: the wrapper verified
    # key.asc, but the drive can be ejected between then and now, and after the
    # next line it is the only way back.
    if not test -f $usb/key.asc
        echo "gpg-master-done: $usb/key.asc disappeared — aborting before delete" >&2
        return 1
    end

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
