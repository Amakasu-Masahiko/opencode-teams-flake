# Running the opencode
With `nix` installed and `flakes` enabled in `/etc/nix/nix.conf` via:
```quote
experimental-features = nix-command flakes
```
Run in top of the repository following command:
```bash
nix run .
```
