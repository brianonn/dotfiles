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
640kbps (skipped if the file already has a suitable AC-3 or E-AC-3 surround track). The new tracks are merged into the
file and set as default and non-default as described below. The original audio tracks are kept.

If the file already has a suitable stereo AAC track, that track is reused and no new AAC track is created. Suitable
means: codec AAC, 2 channels, language `eng`, `en`, or `und`, and not commentary, visually-impaired, or description
(the same filters used to select the source track). The language set matches the source selection, so the existing
track does not have to be tagged `eng` specifically. If several qualify, one already flagged default is preferred,
then the lowest track ID.

- **Stereo AAC (160kbps, 48kHz):** downmixed from surround with the center channel boosted (0.70, about +6 dB of
  dialogue lift over the front level) and 0.20 LFE mixed in, then run through a compressor (4:1 above -20 dB, 10ms
  attack, 300ms release, 3 dB knee, 2 dB makeup) and `loudnorm` (-16 LUFS). This track is the default. Skipped when a
  suitable AAC stereo track already exists.
- **AC-3 5.1 (640kbps, 48kHz):** tagged `eng`, named "English 5.1 AC-3", not default. For 7.1 sources the side channels
  are folded into the back pair at 0.707 each. No loudness processing is applied.
- **Default flag:** exactly one stereo AAC track is default, and no other audio track is. When a new AAC track is
  created it is the default. When an existing one is reused, that track is set as default and the other original audio
  tracks are cleared.
- **Nothing to do:** if a suitable AAC track exists, no AC-3 track is needed, and the AAC track is already flagged
  default, the script logs the reused track ID, prints "Nothing to do", and exits 0. It writes no output and does not
  touch the input, even with `-o`.
- **Reused but not default:** if a suitable AAC track exists, no AC-3 track is needed, and the AAC track is not
  flagged default, the file is remuxed (writing `<name>_stereo.mkv`, or replacing the input with `-o`) so that the AAC
  track becomes the default.

Usage:

```sh
add_default_stereo_track.sh [-o] <input.mkv>
```

- Without `-o`, writes `<name>_stereo.mkv` next to the input.
- With `-o`, replaces the input after verification and restores its original atime and mtime.

Requires `mkvmerge`, `mkvextract`, `ffmpeg`, and `jq`.

### Tests

`add_default_stereo_track.sh --run-tests` runs the tests in `tests/add_default_stereo_track/`, next to the script. The
directory is named after the script without its extension. Each test is an executable named `NN-description` (for
example `01-flac-5.1-adds-aac-and-ac3`). The runner calls each test with the script path as its argument. Exit 0 means
pass; any other exit status means fail. The runner prints PASS or FAIL for each test, prints the failure message for
failed tests, and exits 1 if any test failed.

Tests build their own synthetic MKVs with `ffmpeg` and `mkvmerge` in a temporary directory, so they need the same tools
as the script. `_common.sh` in that directory holds shared helpers and is not run as a test.

`--run-tests` is a development feature. The `tests/` directory is not deployed to `~/.local/bin`, so outside the dotfiles
repository the option prints that it is development-only and exits 1.

| Test | What it checks |
|---|---|
| 01-flac-5.1-adds-aac-and-ac3 | 5.1 FLAC source adds stereo AAC and AC-3 5.1 (+2), AAC default |
| 02-ac3-5.1-adds-aac-only | Existing AC-3 5.1 skips AC-3 creation; only AAC is added (+1) |
| 03-existing-aac-default-nothing-to-do | Default stereo AAC already present: "Nothing to do", no output, input unchanged with `-o` |
| 04-existing-aac-not-default-remuxed | Non-default stereo AAC is reused and remuxed to become default |
| 05-existing-aac-not-default-overwrite | Same with `-o`: input replaced, no temp files left behind |
| 06-no-english-tracks-fails | Only a French track: refuses with an error and writes no output |
| 07-commentary-ac3-not-skipped | A commentary AC-3 5.1 does not count as existing surround; AC-3 is still created (+2) |
| 08-stereo-flac-adds-aac-only | Stereo source with no AAC: only AAC is added (+1), no AC-3 |
| 09-existing-eac3-51-skips-ac3 | Existing E-AC-3 5.1 skips AC-3 creation; only AAC is added (+1) |

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
6. Look for an existing suitable AAC track (AAC, 2 channels, `eng`/`en`/`und`, not commentary, visually-impaired, or
   description). If one is found, log its ID and skip creating a new AAC track. Otherwise create one.
7. If no new track is needed (no AAC and no AC-3) and the reused AAC track is already default, print "Nothing to do"
   and exit 0 before any temp files or output are created. If the reused AAC track is not default, remux the file to set
   it as the default track.
8. Build the track order. New inputs are numbered in the order they are passed to `mkvmerge`: video, new AAC (`1:0`,
   only if created), optional AC-3 (next index), original audio, then other tracks. A reused AAC track stays in the
   original audio order.
9. Clear the default flag on all original audio tracks. If an AAC track was reused, set its default flag instead.
10. Extract the selected track with `mkvextract`.
11. If a new AAC track is needed, encode it. Multichannel sources use a pan matrix (fronts 0.35, center 0.70, backs and
    sides 0.25, LFE 0.20) followed by the compressor and `loudnorm` chain. Stereo and mono sources are encoded directly
    with the same chain.
12. If needed, encode the AC-3 5.1 track. 7.1 sources are downmixed to 5.1 first. Skipped when step 5 found an
    existing surround track.
13. Merge everything with `mkvmerge`, using the track order and flags above. The AC-3 and AAC inputs are only added
    when they were created.
14. Verify the output:
    - it is non-empty;
    - the track count is the original plus the number of tracks added (+1 for AAC only or AC-3 only, +2 for AAC and
      AC-3);
    - it has at least one default audio track, and that includes a default 2-channel AAC track;
    - when AC-3 was created, a 6-channel AC-3 track exists (the check is skipped when AC-3 was skipped, so pre-existing
      AC-3 tracks do not cause a failure);
    - when tracks were added, the file is larger than the original.
15. With `-o`, copy the original permissions onto the output, `mv` it over the input, and restore the saved atime and
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
- **Existing AAC is reused as-is:** a suitable AAC 2-channel track is not re-encoded or checked for quality. Its codec
  and bitrate are kept, so a low-bitrate or `und` track is reused over a better source that the script would not
  otherwise pick.
- **Re-running the script** on its own output does not add another stereo AAC track, and an AC-3 track is not added a
  second time either. For 2-channel sources the second run exits with "Nothing to do" once the AAC track is default.
- **AC-3 skip check covers only eng/en/und tracks:** a 5.1 AC-3 track in another language (for example `fre`) does not
  prevent the English AC-3 track from being created. Commentary, visually-impaired, and description tracks are ignored
  by this check too.
