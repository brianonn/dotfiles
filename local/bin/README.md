# Local Scripts Documentation

This file contains source for simple shell scripts, python scripts or even go scripts :)

This directory is the ultimate source of truth for my ~/.local/bin directory and each of these files will be symlinked
into my ~/.local/bin

Since other 3rd partys, and github installers, etc often install directly into ~/.local/bin, I must not just copy this
entire directory over or symlink at the top-level (i.e. ~/.local/bin -> this/path/bin )

Instead, the setup script at the root of this dotfiles repo will symlink all files from there to here.

## add_default_stereo_track.sh

### Description

Adds a stereo AAC track to an MKV file and, when the source audio is 5.1 or 7.1, also adds an AC-3 5.1 track at
640kbps (skipped if the file already has a suitable AC-3 or E-AC-3 surround track). The new tracks are merged into the file and set as default and non-default as described below. The original
audio tracks are kept.

- **Stereo AAC (160kbps, 48kHz):** downmixed from surround with the center channel boosted (0.70, about +6 dB of
  dialogue lift over the front level) and 0.20 LFE mixed in, then run through a compressor (4:1 above -20 dB, 10ms
  attack, 300ms release, 3 dB knee, 2 dB makeup) and `loudnorm` (-16 LUFS). This track is the default.
- **AC-3 5.1 (640kbps, 48kHz):** tagged `eng`, named "English 5.1 AC-3", not default. For 7.1 sources the side channels
  are folded into the back pair at 0.707 each. No loudness processing is applied.

Usage:

```sh
add_default_stereo_track.sh [-o] <input.mkv>
```

- Without `-o`, writes `<name>_stereo.mkv` next to the input.
- With `-o`, replaces the input after verification and restores its original atime and mtime.

Requires `mkvmerge`, `mkvextract`, `ffmpeg`, and `jq`.

### Flow

1. Parse the optional `-o` flag and check the input file and dependencies.
2. If overwriting, save the input's atime and mtime.
3. Run `mkvmerge -J` once to read the container metadata.
4. Select the best audio track: English, `en`, or `und`, excluding commentary, visually-impaired, and description
   tracks. Score by codec (TrueHD/FLAC/PCM 100, DTS-HD 90, DTS 75, E-AC-3 65, AC-3 50, other 25), then add
   2 points per channel. Ties go to the lower track ID. Exit if none is found.
5. Read the source channel count. Consider the AC-3 track only if it is 6 (5.1) or 8 (7.1) channels. If the file
   already has a suitable surround track, skip AC-3 creation and log the existing track's ID and codec. A suitable track
   is AC-3 with 6 channels, or E-AC-3 with 6 or 8 channels, in `eng`, `en`, or `und`, excluding the same commentary,
   visually-impaired, and description tracks as step 4.
6. Build the track order: video, new AAC (`1:0`), optional AC-3 (`2:0`), original audio, then other tracks.
7. Clear the default flag on all original audio tracks.
8. Extract the selected track with `mkvextract`.
9. Encode the stereo AAC. Multichannel sources use a pan matrix (fronts 0.35, center 0.70, backs and sides 0.25, LFE
   0.20) followed by the compressor and `loudnorm` chain. Stereo and mono sources are encoded directly with the same chain.
10. If needed, encode the AC-3 5.1 track. 7.1 sources are downmixed to 5.1 first. Skipped when step 5 found an
    existing surround track.
11. Merge everything with `mkvmerge`, using the track order and flags above. The AC-3 input is only added when it was
    created.
12. Verify the output:
    - it is non-empty;
    - the track count is the original plus 1 (AAC only) or plus 2 (AAC and AC-3);
    - when AC-3 was created, a 6-channel AC-3 track exists (the check is skipped when AC-3 was skipped, so pre-existing
      AC-3 tracks do not cause a failure);
    - the file is larger than the original.
13. With `-o`, copy the original permissions onto the output, `mv` it over the input, and restore the saved atime and
    mtime. Otherwise print the output path. A trap removes temporary files on exit.

### Observations and Caveats

- **Channel layout assumption:** any source with more than 2 channels takes the surround pan path, which references
  FC, LFE, BL, SL, BR, and SR. Layouts such as 3, 4, or 5 channels may pan incorrectly or fail, since the pan filter
  now also references LFE. Only 6 and 8 channels get an AC-3 track.
- **Overwrite is not atomic with respect to the source:** the output is verified before `mv`, but if the input changes
  while the script runs, that change is lost when the output replaces it.
- **Tracks are picked by score, not by language preference:** an `und` track can outrank a labelled English track if
  its codec or channel count scores higher.
- **Size check:** the output must be larger than the input. Adding tracks normally satisfies this, but the check is
  only a rough sanity test and does not confirm that the new audio decodes correctly.
- **Re-running the script** on a file that already has an added stereo track adds another one. It does not detect
  existing AAC tracks. It does detect an existing surround track for the AC-3 step, so a re-run on a file that already
  has a 5.1 AC-3 or E-AC-3 track adds only the stereo AAC track.
- **AC-3 skip check covers only eng/en/und tracks:** a 5.1 AC-3 track in another language (for example `fre`) does not
  prevent the English AC-3 track from being created. Commentary, visually-impaired, and description tracks are ignored
  by this check too.
