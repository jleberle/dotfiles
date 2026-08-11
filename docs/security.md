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
- **Shell/env hardening** (`shell/fish/conf.d/env.fish`): `umask 077` (owner-only
  by default), `HOMEBREW_NO_INSECURE_REDIRECT`, and a
  `fish_should_add_to_history` filter that keeps space-prefixed and
  secret-bearing command lines out of shell history.
- **Firefox** (`security/betterfox/` submodule + `security/user-overrides.js`):
  `make firefox` concatenates both into a single `user.js` written to the active
  Firefox profile. Personal overrides (Smoothfox scroll tuning, DoH/NextDNS,
  shutdown sanitizing, etc.) live in `user-overrides.js` — Betterfox itself is
  never edited. To update Betterfox: `make betterfox-update`, review the diff,
  then `make firefox`. GitHub also gets a monthly Dependabot PR for the
  submodule so upstream changes are surfaced even if you do not pull them
  manually.

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

- **`make harden`** (sudo): enables the application firewall + stealth mode,
  automatic macOS security updates / security responses, and opts out of Apple
  diagnostics submission.
- **`make touchid`** (sudo): enables Touch ID for `sudo` via `/etc/pam.d/sudo_local`
  (with `pam_reattach` ahead of `pam_tid` so it works inside tmux).
- **FileVault**: not toggled here (enabling headless is unsafe), but
  `make macos-check` warns if full-disk encryption is off (`make check` runs it).
- **Backup integrity**: `archbackup check` runs `restic check` on the encrypted
  research-scan repo; `make resticcheck` schedules it weekly (see
  [Automation → Launchd](automation.md#launchd)).

`make macos-check` verifies the `harden`/`touchid`/FileVault state.
