# Recreating this desktop

This recipe targets this Arch/CachyOS desktop and its SteelSeries Apex 3 TKL.
It separates reusable configuration from private machine/application state.
Nothing below requires committing credentials or saved window titles to Git.

## Before reinstalling

Keep the repository and a private archive on another drive. Make a new archive
whenever the saved layout or local preferences change:

```sh
~/dots/bin/desktop-backup --output /run/media/bertold/Media/Backups/Desktop/desktop-$(date +%Y%m%d-%H%M%S).tar.gz
```

The first archive created during this work is
`/run/media/bertold/Media/Backups/Desktop/desktop-20261117-230710.tar.gz`.
Archives contain the saved Hyprland session, local Haruna/Flameshot preferences,
custom commands when present, the update timer, and original OpenRGB system
configuration/profiles. Files are private (mode 600); newly created backup
folders use mode 700. These archives are not encrypted: protect the Media drive.
Session commands can contain private arguments. Keep archives outside the repo.

This is a desktop-state backup, not a home-directory backup: browser profiles,
mail, passwords, VPN/Wi-Fi secrets, TIDAL tokens, games and application data need
separate backups or sign-in. Media-drive mount paths must exist before restoring
windows whose commands refer to that drive. Run hypr-save.sh before backup if
current window placement should replace the saved layout.

## Fresh installation

1. Install a compatible CachyOS/Arch system, graphics drivers and the required
   repositories. Enable multilib for Steam. Network access and sudo must work.
   Package installation does not configure drivers or repositories.
2. Clone the dotfiles and initialise submodules:

   ```sh
   git clone --recurse-submodules YOUR_DOTFILES_URL ~/dots
   cd ~/dots
   ./packages.sh --list
   ./packages.sh
   ./install.sh
   ```

   `all` installs every profile. See packages.md for selectable profiles. Package
   and AUR review prompts remain enabled. The Tabular submodule mapping now
   points to its upstream repository and recorded commit.
3. Preview and then apply service enablement as your regular user:

   ```sh
   ~/bin/desktop-setup
   ~/bin/desktop-setup --apply --serial
   ```

   This enables NetworkManager, Bluetooth, OpenRGB, PipeWire sockets,
   WirePlumber and the update timer. It does not start/restart services or
   overwrite root OpenRGB settings. `--serial` optionally grants uucp membership
   for Arduino access; log out and back in for that membership to take effect.
   Omit it if serial access is not wanted. Package-provided OpenRGB udev rules
   are required; no blanket device permissions or ACPI overrides are installed.
   Existing USB devices may need reconnecting after package/rule installation.
4. Restore the private archive AFTER running install.sh:

   ```sh
   ~/bin/desktop-backup --restore /path/to/desktop-backup.tar.gz
   ```

   Existing home files receive timestamped backups. System files are staged in
   `~/.local/state/desktop-restored-system/<timestamp>/etc/openrgb`, not applied
   automatically. The tool rejects unknown paths, links, duplicate members and
   oversized members. It refuses symlinked destination parents. On the same
   hardware, review staged files before copying them into /etc/openrgb with sudo;
   preserve any existing system configuration first. The keyboard schedule does
   not require copying those root files: managed user profiles are sufficient.
5. Select Zsh as your login shell if desired (`chsh -s /usr/bin/zsh`), log into
   Hyprland, then install tmux plugins with prefix + I after loading the config.
   Use `hypr-restore.sh` to launch the private saved session. Restored commands
   require their applications and private credentials to be present.

## What is managed

- Haruna and Flameshot preferences are copied from sanitized templates, not
  symlinked: those apps write recent paths/history back into their settings.
  Re-running install.sh backs up differing files and reapplies these defaults;
  restore private preferences afterwards when needed. History paths and the
  machine-specific screenshot directory are intentionally absent from templates.
- `config/openrgb/profiles` contains keyboard-only cyan/friday profiles, without
  USB paths or serial identifiers. The helper prefers these user profiles,
  supports OPENRGB_PROFILE_DIR, and falls back to /etc/openrgb/profiles for old
  installs. It detects the current keyboard directly. Cyan is selected Mon–Thu;
  friday Fri–Sun, at login. GPU/mainboard settings remain private hardware state.
- Hyprland launches desktop-session-startup, which imports only display-related
  variables into the user manager and starts the packaged Mako/Hyprpaper units.
  The system OpenRGB server is separate; keyboard lighting does not rely on its
  cached device handles. Avoid adding duplicate XDG autostarts for these helpers.
- Snapshot geometry assumes the same monitor names/resolution/scale. Update
  monitor assignments (including Mako's DP-2 output) for different hardware.
- OpenRGB RAM/SMBus access may additionally need hardware-specific i2c-dev,
  i2c permissions and firmware checks. This recipe does not force ACPI resource
  access or assume an I2C bus/address on a replacement motherboard.

## Verification and limits

Implementation files:

- `install.sh`: backup-aware links and private copies of application templates.
- `bin/desktop-setup`: service-enable preview/apply and optional serial group setup.
- `bin/desktop-session-startup`: imports WAYLAND_DISPLAY, DISPLAY,
  HYPRLAND_INSTANCE_SIGNATURE and XDG_CURRENT_DESKTOP when set, then starts Mako
  and Hyprpaper as user services. It requires no sudo.
- `bin/desktop-backup` and `bin/desktop_backup.py`: private archive creation and restore.
- `config/systemd/user/arch-update.timer`: the existing update-check schedule.
- `tests/test_desktop_restore.py`: six isolated regression/rehearsal tests.

Current-machine changes made on 2026-11-17: the login helper and user keyboard
profiles were linked into place; application preference templates were prepared
for future installation, without replacing the current Haruna/Flameshot files.
Required service enablement and uucp membership were verified as already present.
No services were restarted, and no private archive was restored over this session.
The new login helper runs at the next Hyprland login. The working-tree changes
remain uncommitted; a remote clone will not contain them until committed/pushed.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_desktop_restore.py -v
bash -n install.sh packages.sh bin/desktop-setup bin/desktop-session-startup bin/desktop-backup
systemctl is-enabled NetworkManager bluetooth openrgb
systemctl --user is-enabled pipewire.socket pipewire-pulse.socket wireplumber arch-update.timer
```

The automated rehearsal copies the current tracked/new files into a temporary
repository-shaped directory, installs into a fresh temporary HOME twice, checks
links, backups and copied settings, mocks package transactions, and tests private
state restoration/archive rejection. It does not install packages or touch live
services. A booted VM/hardware reinstall has not been tested; this rehearsal
cannot verify graphics drivers, actual downloads, USB permissions or visual output.
The real private archive was created and inspected for member names/permissions;
it was not restored over the running desktop.
