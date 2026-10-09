# ggj25: [wishbones](https://avivajpeyi.itch.io/wishbones)
global game jam '25

Build and upload the Web game to itch.io:

```bash
./publish.sh
```

Use `--build-only` to export without uploading, `--dry-run` to check the upload,
or `--check` to check tool discovery. Output is in `build/web` and
`build/wishbones-web.zip`. Set `GODOT_BIN` to override Godot (matching Web export
templates required), `BUTLER` to override Butler, or `ITCH_TARGET` to override
`avivajpeyi/wishbones:html5`.

CPU players, gameplay evidence, validation and tuning: [CPU implementation](docs/cpu_players/README.md).
