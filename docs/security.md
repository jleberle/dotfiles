# Security

The security posture in one paragraph: SSH and GPG only accept modern
cryptography, SSH keys live in the Mac's Secure Enclave behind Touch ID, the
GPG master key stays offline on a USB drive, every commit is scanned for
secrets before it lands, and Firefox runs a hardened profile. Most of it is
set up once by `make security` and verified afterward by `make doctor`.

Configs symlinked by `make security`:

- **SSH** (`security/ssh-config`): modern crypto only — hybrid post-quantum key
  exchange first (ML-KEM / sntrup761 + x25519), AEAD-only ciphers (AES-256-GCM
  preferred, ChaCha20-Poly1305 fallback), ETM MACs, `IdentitiesOnly`, agent +
  Keychain integration, strict host-key checking, connection multiplexing for
  Codeberg (`ControlPath ~/.ssh/control/%C`, persisted 10m), no agent/X11
  forwarding, `github-443` fallback for networks that block port 22.
  A key-algorithm floor (`PubkeyAcceptedAlgorithms`/`HostKeyAlgorithms` +
  `RequiredRSASize 3072`) refuses `ssh-rsa`/SHA-1, DSA, and short RSA keys.
  ECDSA P-256 is permitted (alongside Ed25519/RSA-SHA2) because Secure-Enclave
  keys must be P-256 — see SSH key custody below.
- **Pinned host keys** (`security/known_hosts` → `~/.ssh/known_hosts_pinned`):
  GitHub/Codeberg host keys are pre-trusted via a second `UserKnownHostsFile`,
  removing the trust-on-first-use prompt (and its MITM window) on a fresh
  machine. Fingerprints are documented in-file; re-verify against the providers'
  docs and update when they rotate.
- **GPG** (`security/gpg.conf`, `gpg-agent.conf.tmpl`, `dirmngr.conf`, `common.conf`):
  hardened algorithm preferences (AES-256 / SHA-512), strong S2K, `pinentry-mac`,
  `import-minimal`/`export-minimal`, `no-allow-loopback-pinentry`, `use-keyboxd`
  (`common.conf`), privacy-conscious keyserver/dirmngr defaults (LDAP disabled).
  `auto-key-locate local,wkd` omits keyservers so key lookups don't leak the
  queried key ID. Git commit and tag signing uses GPG (`gpg.format = openpgp`) —
  the same key works across GitHub and Codeberg without cross-registering SSH keys.
  Note that `~/.gnupg/gpg-agent.conf` is **generated**, not symlinked: `make
  security` (and therefore `make install`) rewrites it from
  `security/gpg-agent.conf.tmpl` every time, substituting the Homebrew prefix.
  Edits made to the file in `~/.gnupg` are discarded on the next run — change
  the template instead. The generated file says so in its own header.
- **GPG master key management**: `gpg-master-import` / `gpg-master-done` fish
  functions handle the import-edit-cleanup cycle for the offline master key.
  `gpg-master-done` detects the machine (Leia/Ahsoka), reimports only the correct
  machine-specific subkeys, and stages the export inside `~/.gnupg` under
  `umask 077` (never a predictable `/tmp` path).
- **Secret scanning + git integrity** (`git/hooks/pre-commit`, `gitconfig`):
  a global `core.hooksPath` runs `gitleaks` on staged changes before every
  commit, and `*.fsckObjects` reject malformed objects on fetch/clone. See
  [Git](git.md).

  Three layers, each covering a gap the others leave. The pre-commit hook stops
  a secret before it is committed. CI re-scans the **whole history** on every
  push — which needs `fetch-depth: 0` in the workflow, because checkout defaults
  to a one-commit clone and gitleaks then only sees the tip, so a secret that was
  committed and later deleted passes clean. GitHub's own secret scanning and push
  protection catch known provider tokens (AWS, Stripe, GitHub) across history,
  but non-provider patterns are off, which is exactly the generic/high-entropy
  space gitleaks covers.
- **Shell/env hardening** (`shell/fish/conf.d/env.fish`): `umask 077` (owner-only
  by default), `HOMEBREW_NO_INSECURE_REDIRECT`, and a
  `fish_should_add_to_history` filter that keeps space-prefixed and
  secret-bearing command lines out of shell history.

  The umask earns its keep on material that leaves the machine with its modes
  attached — the GPG master key staged for USB, restic snapshots (which preserve
  and restore modes), the Keynote decks synced to Drive. It is *not* the main
  defense against other local accounts; `make harden` setting `~` to `0700` is,
  because that holds for files this shell never touched (what an app creates,
  what a backup restores, anything predating the umask) and because you can see
  it with `ls -ld ~` instead of inferring it.

  Because `conf.d` is sourced for every fish session including scripts, the umask
  propagates into whatever you launch. That is wrong for Homebrew, which installs
  world-readable software, so `make apps` and `bin/homebrewupdate.sh` set
  `umask 022` explicitly; `make brew-check` warns if the Cellar has already
  drifted. Anything else that installs software for general use should do the
  same.
- **Firefox** (`security/betterfox/` submodule + `security/user-overrides.js`):
  `make firefox` concatenates both into a single `user.js` written to the active
  Firefox profile. Personal overrides (Smoothfox scroll tuning, DoH/NextDNS,
  shutdown sanitizing, etc.) live in `user-overrides.js` — Betterfox itself is
  never edited. To update Betterfox: `make betterfox-update`, review the diff,
  then `make firefox`. GitHub also gets a monthly Dependabot PR for the
  submodule so upstream changes are surfaced even if you do not pull them
  manually.

  **The profile's `user.js` is generated — never edit it.** `make firefox`
  overwrites it whole, and the file carries a header saying so. Betterfox's own
  header, further down that file, tells you to edit `user.js` to make lasting
  changes; that advice is for a hand-installed Betterfox, not this setup. Put
  your changes in `user-overrides.js`. Firefox itself never writes `user.js`, so
  the overwrite loses nothing but hand edits.

  **Deleting a pref does not revert it.** `user.js` only *sets* values, once per
  startup — the value then persists in the profile's `prefs.js`. Removing a line
  from `user-overrides.js` therefore leaves the old setting in force on any
  profile that already applied it. To undo a pref, set it explicitly to the
  value you want and re-run `make firefox`. This is why the WebAuthn override is
  written as an explicit `true` rather than simply deleted.

## SSH key custody (Secretive)

The `secretive` cask stores SSH keys in the **Secure Enclave**:
non-exportable, hardware-bound, Touch-ID-gated. Keys are generated in the
enclave (you cannot import existing keys) and are per-machine, so each Mac gets
its own key registered with each provider. Because the enclave only supports
NIST P-256, these are ECDSA keys — hence the `PubkeyAcceptedAlgorithms` allowance
above. `env.fish` points `SSH_AUTH_SOCK` at Secretive's socket (guarded on its
existence) so `ssh`, `git`, **and** `ssh-keygen` all use the enclave keys —
the last matters for `ssh-keygen -Y sign` (Codeberg/Forgejo key verification),
which ignores `ssh_config`'s `IdentityAgent`. Per-machine setup steps live in
`security/ssh-config`.

## Optional system hardening (separate targets)

Not part of `make install` — each touches system state and most need `sudo`:

- **`make harden`** (sudo): sets the home directory to `0700`, enables the
  application firewall + stealth mode, automatic macOS security updates /
  security responses, and opts out of Apple diagnostics submission.
- **`make touchid`** (sudo): enables Touch ID for `sudo` via `/etc/pam.d/sudo_local`
  (with `pam_reattach` ahead of `pam_tid` so it works inside tmux).
- **FileVault**: not toggled here (enabling headless is unsafe), but
  `make macos-check` warns if full-disk encryption is off (`make check` runs it).
- **Backup integrity**: `archbackup check` runs `restic check` on the encrypted
  research-scan repo; `make resticcheck` schedules it weekly (see
  [Automation → Launchd](automation.md#launchd)). A run that finds the drive
  unmounted exits 0 on purpose — the drive is normally unplugged, and a weekly
  failure for that would train you to ignore the job. So that a skip can never
  be mistaken for a pass, a successful check stamps
  `~/.local/.restic_verified`, and `make doctor` warns once that stamp is
  missing or older than 35 days (`RESTIC_VERIFY_MAX_AGE_DAYS` in the Makefile).
  Without it, a machine whose drive is never plugged in logs "skipping check"
  every Sunday forever while every health check stays green.

`make macos-check` verifies the `harden`/`touchid`/FileVault state.
