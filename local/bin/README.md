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
640kbps. The new tracks are merged into the file and set as default and non-default as described below. The original
audio tracks are kept.

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
- **Nothing to do:** if a suitable AAC track exists and no AC-3 track is needed, the script logs the reused track ID,
  prints "Nothing to do", and exits 0. It writes no output and does not touch the input, even with `-o`. In this case the
  file is not rewritten, so an existing AAC track that is not flagged default stays that way. The script prints a note
  when this happens.

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
5. Read the source channel count. Create the AC-3 track only if it is 6 (5.1) or 8 (7.1) channels.
6. Look for an existing suitable AAC track (AAC, 2 channels, `eng`/`en`/`und`, not commentary, visually-impaired, or
   description). If one is found, log its ID and skip creating a new AAC track. Otherwise create one.
7. If no new track is needed (no AAC and no AC-3), print "Nothing to do" and exit 0 before any temp files or output
   are created.
8. Build the track order. New inputs are numbered in the order they are passed to `mkvmerge`: video, new AAC (`1:0`,
   only if created), optional AC-3 (next index), original audio, then other tracks. A reused AAC track stays in the
   original audio order.
9. Clear the default flag on all original audio tracks. If an AAC track was reused, set its default flag instead.
10. Extract the selected track with `mkvextract`.
11. If a new AAC track is needed, encode it. Multichannel sources use a pan matrix (fronts 0.35, center 0.70, backs and
    sides 0.25, LFE 0.20) followed by the compressor and `loudnorm` chain. Stereo and mono sources are encoded directly
    with the same chain.
12. If needed, encode the AC-3 5.1 track. 7.1 sources are downmixed to 5.1 first.
13. Merge everything with `mkvmerge`, using the track order and flags above.
14. Verify the output:
    - it is non-empty;
    - the track count is the original plus the number of tracks added (+1 for AAC only or AC-3 only, +2 for AAC and
      AC-3);
    - it has at least one default audio track;
    - when AC-3 was requested, a 6-channel AC-3 track exists;
    - the file is larger than the original.
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
- **Re-running the script** on its own output does not add another stereo AAC track. For 2-channel sources the script
  exits with "Nothing to do". For 5.1 or 7.1 sources, the AC-3 track is still added on each run, because AC-3 existence
  is not checked by this change (see DTF-M36P).
