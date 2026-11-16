# Samsung Galaxy A56 5G (SM-A566B) — A566BXXUEDZJ1 Firmware Analysis

## Scope and safety

This is an offline analysis of the original firmware release. It does not flash
an image, change device state, alter AVB, or execute any payload on a device.
The large source assets are intentionally outside Git history.

## Reproducibility

Run `tools/analyze-a566b-firmware.sh <parts-directory> <output-directory>` on
a Linux host with `sha256sum`, `unzip`, `tar`, `lz4`, `gzip`, `grep`, and `dd`.
The tool verifies the reconstructed ZIP before extraction, extracts only the
boot-relevant AP images, and recovers the embedded kernel configuration.

## Verified firmware inventory

The release contains eleven split parts. Concatenation in numerical order
produced a 11,175,621,942-byte ZIP. `unzip -t` completed without errors.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Reconstructed ZIP | 11,175,621,942 | `e92f7fb018d97bdb9a0a0ad8076ba8179b0f29910453fde0fe1474cc3fa54c84` |
| AP | 12,754,862,203 | `85872dfc6c53ebb9146a68894dbb85b7eb7c378b09ed44c5d57756b70cc8e008` |
| BL | 9,687,153 | `36adb6dace05953d6d9e9e86512be5c4f78580ec31d91a68022e83cb31c0a6b7` |
| CP | 73,513,070 | `2ad75c684f70afcbb7f6108a704749b1d1817a91e5eaf925032808ec55c59490` |
| CSC | 242,370,664 | `25b2f9f78f851d85334be30a72eb027a9ef0af17f28ef33674c9fe5becf0673d` |
| HOME_CSC | 242,339,949 | `304a07be06717cd5ba42666f5054b9b2bc5fd57910c898e47f57a9c4e5e723e2` |

The split-part SHA-256 values, in concatenation order, are:

```
001 ba5630d5b3c58ce13f3bc34cbb60e309f46880579fcfaa03067439f6e1004ecf
002 67fd0732e8fb77262823d4d1d130700cffe2d3060e1e56b4c06676b118a69f5f
003 c31441edd8e25241be4db11ffdd0a912ef47f60ca8bc909fa88671281041f9d2
004 e6647817f5d13c78419058ad836c984d752ab94e1e4e330b6522a694b015f232
005 33dd8892bf9fd7756d5bf9954d2415882d53d376a7eb060e3fe419cfaf2c38e2
006 8d76ea4fd7f0f7b626706e0e6a95d4fa0851e9211422ebec05c24fd1ad7919db
007 e6fab530254ed2c6185ec018255040d99ab09caecc64a704e095e86e3b6ff74b
008 8be12cf6f89b84a5bab1dc72ca312abf5615e1d7f7bafb34e2c892d0cddc023b
009 1c5cdef772f39f13ad518a9eee6bf54879cf3b50f4b6111ed696f24ce8ba0ddb
010 b788f26e8923cda6b4f65472fa641fcb9ef3f6f31ddc59135516cb09d2822572
011 1b7b5cfaea88ed7820f153cd37fad9361307305012e81ee0410af8625dd1add7
```

| Decompressed image | SHA-256 |
| --- | --- |
| `boot.img` | `c960dca8b2a2dab5000c5246e854f6bdaefdd7a67d06cd74e3196b9d1c5d7b69` |
| `init_boot.img` | `65882db492d04386c255cf9b06ee2becd097a0fdc95bb90db34021180410aa75` |
| `vendor_boot.img` | `f09ce2048ea441cf5012fa14074fde97766b08e5d792309cff06bcdef034b698` |
| `dtbo.img` | `c0c5e187d0899c3316958d069c7c0e044568c52468a42fe7aca07e814833aad9` |
| `vbmeta.img` | `a79ebca88a7f7397b0584e9f8ceb11671037b22dbf0a47313eac600a895598f7` |
| `vbmeta_system.img` | `aa011b54358f662207331d7b8f5a0cbc9d3b6f9fa076f9ba0a914aa54d003679` |

AP contains `boot.img.lz4`, `init_boot.img.lz4`, `vendor_boot.img.lz4`,
`dtbo.img.lz4`, `vbmeta.img.lz4`, and `vbmeta_system.img.lz4`. Their
decompressed sizes are respectively 64 MiB, 16 MiB, 112 MiB, 8 MiB, 9,872
bytes, and 4,432 bytes. The boot images contain Android boot headers and the
VBMeta images contain an AVB 1.4.0 footer. The metadata records the Android
security patch level as 2026-10-05.

## Kernel findings

The boot image embeds this build string:

```
Linux version 6.6.127-android15-8-abA566BXXUEDZJ1-4k
#1 SMP PREEMPT Thu Oct 1 04:50:50 UTC 2026
```

It was built with Android Clang 18.0.0. The recovered `IKCONFIG` is 214,940
bytes (`sha256: bb20f6a651b7f75ed2cd811be84bc9400f0b53787101b69678fc0c324178ec04`).
Relevant confirmed settings include 4 KiB pages, 39-bit virtual addresses,
48-bit physical addresses, relocatable-kernel KASLR, Clang CFI, BTF and BTF
module debug information, strict kernel/module RWX, pointer authentication,
BTI, MTE, hardened user-copy, slab freelist hardening, shuffled allocation,
RKP, KDP, SELinux, DEFEX, and signed modules. `CONFIG_LTO_NONE=y`; CFI is
nevertheless enabled by `CONFIG_CFI_CLANG=y`.

These static findings establish capability and hardening configuration only.
They do not establish a runtime slide, symbol addresses, AVB unlock status, or
whether a device accepts any operation.

## Root My Galaxy compatibility assessment

The checked upstream app at commit `23adf39` selects a profile using an exact
model match and the three-component numeric kernel version. The current
payload feed has one A56 profile, `essi-A566EXXSCCZG6`, for `SM-A566B` and
kernel `6.6.102` only. This firmware is `6.6.127`; it therefore has no
matching supported profile.

Issue [#692](https://github.com/BuSung-dev/Root-My-Galaxy/issues/692)
documents a kernel panic on the earlier `A566BXXSECZI2` / 6.6.102 firmware
while using that profile. Issue [#809](https://github.com/BuSung-dev/Root-My-Galaxy/issues/809)
requests support for this exact `A566BXXUEDZJ1` / 6.6.127 combination and is
open. The public app source states that offsets and native exploit payloads
are maintained separately; the relevant payload is published as a binary
artifact, not as buildable source in the app repository.

### Conclusion

No new Root My Galaxy profile was created. An exact-build profile would need
independent source-level review or authoritative vendor symbols, a complete
set of build-specific validation evidence, and an authorized, recoverable
hardware test. The old 6.6.102 profile must not be relabelled for 6.6.127:
the static configuration and the prior panic provide no basis for claiming
compatibility. This repository contains only safe offline analysis material.
