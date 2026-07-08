# Mail: NeoMutt + Proton Bridge

A local-first mail setup: **Proton Bridge** exposes Proton Mail over local
IMAP/SMTP, **mbsync** syncs it to a local Maildir (`~/.mail/proton/`),
**notmuch** indexes it for fast full-text search, and **NeoMutt** reads the
local Maildir and sends via the Bridge. A launchd agent keeps everything in
sync every 5 minutes in the background.

| Layer      | Tool                 | Purpose                                                |
|------------|----------------------|--------------------------------------------------------|
| Gateway    | Proton Bridge        | Decrypts Proton Mail locally; IMAP `127.0.0.1:1143`, SMTP `127.0.0.1:1025` |
| Sync       | mbsync (isync)       | Syncs Bridge IMAP → `~/.mail/proton/` Maildir          |
| Index      | notmuch              | Full-text search over the local Maildir                |
| Client     | NeoMutt              | Reads local Maildir; sends via Bridge SMTP             |
| Background | launchd              | Runs `mailsync` every 5 minutes                        |

The Bridge must be running for sync and send to work — the background sync
exits quietly when it isn't.

## One-time setup

`make neomutt` symlinks the four config files, creates cache directories,
creates `~/.mail/proton/`, and copies `mbsyncrc` + `notmuch-config` templates
if they don't already exist.

1. **Install and sign in to Proton Bridge**, and note the password it
   generates (Bridge → account → show password). The same password is used
   for IMAP and SMTP.

2. **Run `make neomutt`** to scaffold everything.

3. **Edit `~/.mbsyncrc`** — set `User` to your Proton Bridge email address.

4. **Edit `~/.notmuch-config`** — set `name` and `primary_email`
   (`path` is filled in automatically by `make neomutt`).

5. **Store the Bridge password in Keychain** under a custom service name
   (avoids conflicts with Apple Mail's tokens stored under server hostnames):
   ```fish
   read -s -P "Bridge password: " PASS
   security add-internet-password -s "proton-bridge" -a "neomutt" -T /usr/bin/security -w $PASS
   ```

6. **Edit `~/.config/neomutt/accounts/local.rc`** — use
   `writing/neomutt/accounts/example.rc` as the template. Key settings:
   - `set folder = ~/.mail/proton` — local Maildir root
   - `set nm_default_url = "notmuch:///Users/you/.mail"` — absolute path
   - `set smtp_url` — authenticate as your Bridge login, `From` uses your custom domain
   - the backtick command that fetches `smtp_pass` from Keychain must be
     wrapped in double quotes, or a `%` in the password breaks it
   - On first send, accept the Bridge's self-signed certificate; it persists
     in the file set by `certificate_file`

7. **Initial sync** (Bridge running):
   ```sh
   mbsync -a && notmuch new
   ```

8. **Install background sync:**
   ```sh
   make mailsync
   ```

After this, use `mailsync` in the terminal to sync on demand, or let launchd
handle it automatically. Logs go to `~/.local/mail_sync_logs.txt`.

## Keybindings

| Key              | Mode            | Action                                         |
|------------------|-----------------|------------------------------------------------|
| `A`              | Index / Pager   | Archive message to `=Archive`                  |
| `B`              | Index / Pager   | Open sidebar folder                            |
| `Ctrl-F`         | Index           | Search mail with notmuch (vfolder-from-query)  |
| `Ctrl-U`         | Index / Pager   | Extract and open URLs via urlscan              |
| `Ctrl-P` / `Ctrl-N` | Index / Pager | Previous / next sidebar item                |
| `\Ch`            | Attach / Compose | Open HTML in Firefox                          |
| `Ctrl-R`         | Index           | Mark all messages as read                      |

## GPG/PGP

`writing/neomutt/gpg.rc` uses GPGME with the same key and `gpg.conf` managed
by `make security`. Encrypted replies are automatically encrypted; signed
messages are automatically verified. Toggle signing/encryption per message with
`p` in the compose menu.

## HTML rendering

HTML emails render inline via `w3m`. Press `\Ch` to open in Firefox instead.
Both `w3m` and `urlscan` are in the Brewfile.

## Aliases

`mutt` is aliased to `neomutt`; both commands launch the client.
