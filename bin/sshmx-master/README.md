# sshmx - SSH Session Manager for tmux

`sshmx` is a lightweight Bash utility that helps you manage and launch SSH sessions inside [`tmux`](https://github.com/tmux/tmux).  
It integrates with your existing `~/.ssh/config` or lets you add/remove sessions interactively, and provides handy **tmux key bindings** (`Ctrl+b C-s` for sessions, `Ctrl+b C-g` for groups) to quickly open SSH connections in popup windows.

---

## ✨ Features
- **Interactive SSH session selector** using [fzf](https://github.com/junegunn/fzf) with multi-select and preview
- **Automatic JSON session store** (`~/.ssh/sessions.json`)
- **Import from `~/.ssh/config`** or create sessions manually
- **tmux integration**:
  - New SSH sessions open in dedicated `tmux` windows
  - Popup window shortcuts (`Ctrl+b C-s` for sessions, `Ctrl+b C-g` for groups) to run `sshmx`
- **Jump host (ProxyJump) support**
- **Password and private key support** (passwords are stored encrypted with GPG; `sshpass` is used for authentication when needed)
- **Group support**: Organize and connect to all sessions in a group at once
- **Export/Import sessions** for backups and sharing
- **Optional colored output** with [chromaterm](https://github.com/hSaria/Chromaterm)
- **Host IP resolution** using `getent` (if available)
- **Self-installing** script – just run once and it sets itself up
- **Sync with `~/.ssh/config`** preserving encrypted passwords and groups
- **Logging** for debugging parsing issues
- **Password migration** tool: convert old plaintext passwords to GPG-encrypted format

---

## 📦 Requirements
- [tmux](https://github.com/tmux/tmux)
- [fzf](https://github.com/junegunn/fzf)
- [jq](https://github.com/stedolan/jq)
- [sshpass](https://linux.die.net/man/1/sshpass) *(optional, for password auth)*
- [chromaterm](https://github.com/hSaria/Chromaterm) *(optional, for colored output)*
- `getent` *(optional, for hostname to IP resolution; usually available on Linux)*

---

## 🚀 Installation
Clone the repository and run the script with the `--install` flag:

```bash
git clone https://github.com/yourusername/sshmx.git
cd sshmx
./sshmx --install
```

This will:
* Create a symlink to `~/.local/bin/sshmx`
* Add `Ctrl+b C-s` and `Ctrl+b C-g` bindings to your `~/.tmux.conf` (or create one if missing)
* Add bash completion for command flags
* Add `~/.local/bin` to your PATH (via `~/.bashrc`)

Reload tmux:

```bash
tmux source-file ~/.tmux.conf
```

And source bashrc:

```bash
source ~/.bashrc
```

---

## 🔑 Usage

| Command                        | Description                                                       |
| ------------------------------ | ----------------------------------------------------------------- |
| `sshmx`                        | Launch interactive session selector with `fzf` (multi-select, preview) |
| `sshmx --add` / `sshmx -a`     | Add a new SSH session interactively                               |
| `sshmx --remove` / `sshmx -r`  | Remove one or more sessions interactively (with backup)           |
| `sshmx --install` / `sshmx -i` | Install script, create symlink, add tmux bindings, bash completion |
| `sshmx --sync` / `sshmx -s`    | Sync `~/.ssh/sessions.json` with `~/.ssh/config` (preserves passwords/groups) |
| `sshmx --groups` / `sshmx -g`  | Select and connect to all sessions in chosen group(s)             |
| `sshmx --multiplex` / `sshmx -m` | Select active tmux windows (SSH sessions) and move them to a single synchronized window for multiplex commands |
| `sshmx --demultiplex` / `sshmx -d` | Restore panes from a multiplexed window back to separate windows |
| `sshmx --export` / `sshmx -e`  | Export `sessions.json` to a backup file (prompts for filename)    |
| `sshmx --import` / `sshmx -p`  | Import sessions from a JSON file (overwrites current, backs up existing) |
| `sshmx --migrate-passwords` | Migrate old plaintext passwords in `sessions.json` to encrypted GPG format |
| `sshmx --help` / `sshmx -h`    | Show this help message                                           |

---

### First run
The script auto-generates a `sessions.json` file at `~/.ssh/sessions.json` by parsing your `~/.ssh/config`.  
If no sessions are found, it creates a sample entry.  
On first run without installation, it auto-installs itself.

---

### Launch SSH sessions

```bash
sshmx
```

* Prompts you with an `fzf` selector of available sessions (multi-select, with preview of details)
* Selected hosts open as **new windows** in your tmux session
* If run outside tmux, a new session named `sshmx` is created
* Supports keys, encrypted passwords (via `sshpass` after decryption), jump servers, and optional coloring with `chromaterm`
* Hostnames are resolved to IPs if possible for faster connections

Or use the tmux shortcut: `Ctrl+b C-s`

---

### Use Groups

Organize sessions by adding a `group` field when using `--add`.
To connect to all in a group:

```bash
sshmx --groups
```

or

```bash
sshmx -g
```

* `fzf` shows unique groups with preview of sessions in each
* Select one or more groups; all sessions in them open as tmux windows
* Or use tmux shortcut: `Ctrl+b C-g`

---

### Add a new session

```bash
sshmx --add
```

or

```bash
sshmx -a
```

Prompts for session name, hostname/IP, user (default: current), port (default: 22), private key (optional), password (optional, will be encrypted with GPG), jump server (optional), group (optional).
Appends to `sessions.json`.

---

### Remove sessions

```bash
sshmx --remove
```

or

```bash
sshmx -r
```

Lets you multi-select sessions to delete using `fzf` (with preview).  
A timestamped backup of `sessions.json` is automatically created.

---

### Sync sessions from `~/.ssh/config`

```bash
sshmx --sync
```

or

```bash
sshmx -s
```

Parses `~/.ssh/config` for Host blocks (HostName, User, Port, IdentityFile, ProxyJump).  
Updates or adds sessions in `~/.ssh/sessions.json`, preserving existing passwords and groups.  
Resolves hostnames to IPs if possible. Logs details to `~/.sshmx.log`.

---

### Multiplex / Demultiplex Commands (Synchronized Input Across Hosts)

Use **Multiplex** to combine multiple active SSH windows into a single tmux window with synchronized input enabled — allowing commands to be run on all selected hosts simultaneously.

```bash
sshmx --multiplex
```

or

```bash
sshmx -m
```

Then, to **Demultiplex** and restore each host’s pane back to a separate window:

```bash
sshmx --demultiplex
```

or

```bash
sshmx -d
```

This workflow lets you easily switch between centralized control and individual host sessions.

---

### Export/Import sessions

**Export:**

```bash
sshmx --export
```
or

```bash
sshmx -e
```

Prompts for filename (default: `sessions-backup-YYYYMMDD_HHMMSS.json`); copies `sessions.json` there.

**Import:**

```bash
sshmx --import /path/to/file.json
```

or

```bash
sshmx -i /path/to/file.json
```

Backs up current `sessions.json`, then overwrites with the import file.

---

### 🔐 Migrate Passwords


If you previously stored plain-text passwords in `~/.ssh/sessions.json`, you can securely encrypt them using:


```bash
sshmx --migrate-passwords
```


This command:
- Finds any `password` fields in `sessions.json`
- Encrypts them using **GPG** and replaces them with `password_encrypted`
- Deletes the old plain-text password entries
- Exits immediately after completing the migration


> ⚠️ This command should only be needed once after upgrading from older versions.

---

## 🎨 Background / Foreground Color

The script supports optional **background** and **foreground** color settings for each SSH session. When both `bg_color` and `fg_color` are defined in your `sessions.json`, `sshmx` will:

- Create the tmux window with the specified colors.
- Apply `window-style` and `window-active-style` so the window appears with those colors.

Example entry in `sessions.json`:

```json
{
  "myserver": {
    "host": "example.com",
    "user": "user",
    "port": 22,
    "key": "~/.ssh/id_rsa",
    "bg_color": "black",
    "fg_color": "green"
  }
}
```

> **Note:** Colors must be valid tmux color names or hex codes.

---

## 🖥️ Example Workflow
1. Press `Ctrl+b C-s` (or `C-g` for groups) inside tmux
2. `fzf` shows your saved sessions (or groups) with previews
3. Select one or more
4. New tmux windows open, each running SSH into the chosen host(s)

---

## 📂 Files
* `~/.ssh/sessions.json` → Stores your SSH sessions in JSON format: `{ "session_name": { "host": "...", "user": "...", "port": 22, "key": "...", "password_encrypted": "...", "jump": "...", "group": "...", "bg_color": "", "fg_color": "" } }`
* `~/.sshmx.log` → Log file with parsing and sync details
* `~/.tmux.conf` → Key bindings automatically added here
* `~/.local/bin/sshmx` → Symlink to the script for global usage

---

## ⚠️ Security Notes
* Passwords are stored encrypted in `sessions.json` (field `password_encrypted`) when provided; they are encrypted with GPG. Plain‑text passwords are no longer used.
  → **Highly recommended** to use SSH keys instead (`IdentityFile` in config or key field)
* Temporary configs for jump hosts are auto-cleaned (shredded) after use
* Use export/import carefully; always review backups
* For production, consider encrypting the JSON file or using a secure vault

---

## 🛠️ Roadmap / Ideas
* [x] Encrypted session store (e.g., with gpg or pass)
* [x] On-demand sync with `~/.ssh/config` (`-s / --sync`)
* [x] Advanced UI with [fzf preview](https://github.com/junegunn/fzf#preview-window)
* [x] Grouped sessions (connect to multiple related servers at once with `-g`)
* [x] Multiplex commands (run the same command across selected hosts)
* [x] Export/import session configs (share with teammates via `-e`/`-p`)
* [x] Custom background/foreground color to seperate envs

---

### Tmux Shortcuts
| Shortcut     | Action                  |
|--------------|-------------------------|
| `Ctrl+b C-s` | Open session selector   |
| `Ctrl+b C-g` | Open group selector     |
| `Ctrl+b C-m` | Open multiplex selector |
| `Ctrl+b C-q` | Demultiplex panes back to separate windows |

---

## 🤝 Contributing
Pull requests are welcome!  
If you find a bug or want a feature, open an [issue](../../issues).

---

## 📜 License
MIT License © 2025 mrbooshehri