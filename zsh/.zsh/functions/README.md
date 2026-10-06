# sss — SSH host picker

`sss` is a shell function (`ssh-manager.sh`) that lists the hosts from your
SSH config in [fzf](https://github.com/junegunn/fzf) and connects to the one
you pick. It works the same in **bash** and **zsh**.

```
╭───────────────────────────────────────────────────────────────────────────╮
│ SSH > gw                                     ╭──────────────────────────╮ │
│   3/94 ───────────────────────────────────── │ user admin               │ │
│ ▌ [Home        ] gw-001        home gateway  │ hostname 192.168.1.1     │ │
│   [qbSystems   ] gw-office     vpn gateway   │ port 22                  │ │
│   [Wiliot      ] gw-lab                      │ identityfile ~/.ssh/...  │ │
│ ╭──────────────────── keys ────────────────╮ │                          │ │
│ │ enter ssh   ^t window   ^s sftp   ...    │ │                          │ │
│ ╰──────────────────────────────────────────╯ ╰──────────────────────────╯ │
╰───────────────────────────────────────────────────────────────────────────╯
```

## Features

- **Hosts grouped by file.** Every file in `~/.ssh/conf.d/` is a category;
  its path (relative to `conf.d`) is shown in brackets. Hosts defined
  directly in `~/.ssh/config` are shown as `[config]`.
- **Search comments.** A `#:` line above a `Host` block is shown next to the
  host and is searchable (see [Search comments](#search-comments)).
- **Recent first.** Hosts you used recently are listed at the top; the rest
  keep their category order.
- **Direct connect.** `sss <query>` pre-fills the search and connects
  without showing the menu when exactly one host matches.
- **Extra ssh arguments.** Everything after `--` is passed to ssh:
  port forwards, agent forwarding, a remote command.
- **Preview.** The effective `HostName`, `User`, `Port`, `IdentityFile` and
  `ProxyJump` from `ssh -G`, i.e. after all `Include` and `Host *` rules.
- **Actions** on the selected host: ssh, ssh in a new window, sftp, browse
  in [yazi](https://yazi-rs.github.io/), copy the alias, edit its config.

## Usage

```sh
sss                               # pick a host interactively
sss gw                            # search for "gw"; connect directly on a single match
sss home gw                       # several words form one query: "home gw"
sss gw -- -L 8080:localhost:80    # pass options to ssh
sss gw -- 'uptime; df -h'         # run a remote command
sss -- -A                         # pick interactively, then ssh -A
```

Arguments after `--` are appended after the host (`ssh <host> <args>`);
OpenSSH accepts options there as well as a remote command. They are used
by `Enter` and `Ctrl-T` and ignored, with a warning, by `Ctrl-S` and
`Ctrl-F`.

| Key      | Action                                                         |
|----------|----------------------------------------------------------------|
| `Enter`  | `ssh <host>` in the current terminal                           |
| `Ctrl-T` | `ssh <host>` in a new terminal window                          |
| `Ctrl-S` | `sftp <host>`                                                  |
| `Ctrl-F` | yazi: tab 1 (active) is the remote home, tab 2 the current directory |
| `Ctrl-Y` | copy the host alias to the clipboard                           |
| `Ctrl-E` | open the host's config file in `$EDITOR` at its `Host` line    |
| `Esc`    | cancel                                                         |

The function returns the exit code of `ssh`/`sftp`/`yazi`, `130` on cancel,
and `1` when a query matches nothing.

### Search comments

```sshconfig
#: home gateway, opnsense
#: router
Host gw-001
  HostName 192.168.1.1
```

- Consecutive `#:` lines are joined: `home gateway, opnsense router`.
- The comment belongs to the next `Host` line only. Any other non-blank
  line in between (including a regular `#` comment) detaches it.
- To ssh itself `#:` is an ordinary comment.

### Moving files with yazi (`Ctrl-F`)

yazi opens with two tabs: the remote home directory (tab 1, active) and
the directory you ran `sss` from (tab 2).

| Keys                | Action                                          |
|---------------------|-------------------------------------------------|
| `1` / `2`, `[` / `]`| switch tabs                                     |
| `y` / `x`, then `p` | copy / cut, then paste in the other tab         |
| `t` `t`             | new tab in the current directory                |
| `g` `Space`         | jump to a path; local or `sftp://<name>//abs/path` |
| `Enter`             | open a remote file; saved edits are uploaded back |

Remote URLs: `sftp://<name>/` is the remote home directory,
`sftp://<name>//etc` is the absolute path `/etc`.

The `sftp-cd` yazi plugin (`yazi/.config/yazi/plugins/sftp-cd.yazi` in
these dotfiles, bound to `g` `Space` in `keymap.toml`) pre-fills
`sftp://<name>//` in remote tabs, so only the absolute path is left to
type. In local tabs `g` `Space` behaves as usual.

## Requirements

| Tool | Required | Used for |
|------|----------|----------|
| bash or zsh | yes | the function itself |
| `fzf` ≥ 0.63 | yes | the picker (`--footer` needs 0.63+) |
| OpenSSH (`ssh`, `sftp`, `ssh-keygen`) | yes | connecting, `ssh -G` for the preview and yazi settings, key checks |
| `find`, `awk`, `sed`, `sort`, `grep`, `tail`, `tr`, `cut` | yes | config parsing and history; POSIX versions are enough |
| `yazi` | for `Ctrl-F` | file manager with built-in SFTP; tested with 26.9.1 |
| `wl-copy`, `xclip` or `pbcopy` | for `Ctrl-Y` | clipboard, tried in this order |
| `kitty`, `ghostty` or `xdg-terminal-exec` | for `Ctrl-T` | new window; the current terminal is preferred |
| `$EDITOR` | for `Ctrl-E` | may contain arguments, e.g. `nvim -p`; must accept `+<line>` |

## Installation

The file only defines functions, so it just needs to be sourced.

- **zsh** — `.zshrc` sources every `~/.zsh/functions/*.sh`.
- **bash** — `.bashrc` sources every `~/.config/shell/functions/*.sh`. That
  directory currently holds a **copy** of `ssh-manager.sh`, not a link, so
  changes here must be copied there (or replaced by a symlink).

## Files

### Read

| Path | Purpose |
|------|---------|
| `~/.ssh/conf.d/**` | host list, categories and `#:` comments; subdirectories and symlinked files are followed |
| `~/.ssh/config` | hosts defined in the file itself, as `[config]` |
| `~/.ssh/config` and everything it includes | via `ssh -G`, for the preview and for `Ctrl-F` |
| identity files reported by `ssh -G` | `Ctrl-F` only: checked for existence and whether they need a passphrase |

The host list comes from `~/.ssh/conf.d/` and from `~/.ssh/config` itself.
Other files pulled in by `Include` elsewhere are not scanned for the list
(their settings still apply through `ssh -G`).

Recognised `Host` forms: `Host a b`, `host a`, indented lines, `Host=a`.
Patterns with `*`, `?` or `!` are skipped.

### Created / written

| Path | When | Content |
|------|------|---------|
| `${XDG_CACHE_HOME:-~/.cache}/sss/history` | every `Enter`, `Ctrl-T`, `Ctrl-S`, `Ctrl-F` | last 200 used host aliases, newest at the bottom |
| `${YAZI_CONFIG_HOME:-${XDG_CONFIG_HOME:-~/.config}/yazi}/vfs.toml` | `Ctrl-F` | `[sftp.<name>]` sections for yazi, mode `600` |

Temporary `*.tmp` files next to both are used for atomic updates and
removed afterwards. The terminal title is set to `SSH: <host>` while
connected and reset afterwards.

## yazi integration details

yazi's SFTP client does not read `ssh_config`, so on `Ctrl-F` `sss`:

1. Resolves the host with `ssh -G`: `hostname`, `user`, `port` and the first
   identity file that exists.
2. Drops the key if it needs a passphrase (`ssh-keygen -y -P ''` fails);
   yazi then authenticates through `ssh-agent` (`$SSH_AUTH_SOCK`).
   Passphrases and passwords are never written.
3. Writes the section into `vfs.toml` inside a managed block:

   ```toml
   # >>> sss (generated by sss, edits are overwritten)
   [sftp.gw-001]
   host = "192.168.1.1"
   user = "admin"
   port = 22
   key_file = "/home/you/.ssh/id_ed25519"

   # <<< sss
   ```

   Only this block is rewritten, and only the section of the selected host.
   Anything outside it is left alone. A section with the same name defined
   by hand outside the block wins and is used as is, which is how to
   override the generated settings.
4. Runs `yazi "$PWD" "sftp://<name>/"`.

`<name>` is the alias converted to yazi's rules (kebab-case, at most 20
characters): `Weebit-Nano_Prod.Server` → `weebit-nano-prod-ser`. Two aliases
that convert to the same name share one section, which always holds the
host opened last.

`vfs.toml` contains host addresses and user names. If yazi's config is ever
managed from this repo, keep `vfs.toml` out of git.

## Limitations

- **yazi does not support `ProxyJump`, `ProxyCommand`, `Match` or
  `ControlMaster`.** Use `Ctrl-S` (sftp) for such hosts.
- Remote files in yazi are not previewed until downloaded (e.g. opened).
- Host aliases containing spaces or tabs are not supported (ssh does not
  allow them either).
- The hint footer needs about 65 columns in the list pane; it is cut off in
  narrower terminals.
