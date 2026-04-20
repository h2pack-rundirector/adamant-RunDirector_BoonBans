# BoonBans

> Controls which blessings are offered to you by Gods/NPCs/Keepsakes.

Part of the [Run Director modpack](https://github.com/h2pack-rundirector/run-director-modpack).

## What It Does

BoonBans lets you trim, bias, and reshape the boon offer pool across multiple sources.

The module is split into four main scopes:

- `Olympians`
  Standard god boon pools, including normal boons and special entries such as duo, legendary, and infusion-style traits where applicable.
- `Other Gods`
  Non-standard god-like boon sources that still feed into the offer system.
- `Hammers`
  Weapon-upgrade style offer pools.
- `NPCs`
  NPC, keepsake, and related directed boon sources.

Within those scopes, the module can:

- ban individual boons so they stop appearing from that source
- force rarity behavior for eligible boons
- filter large boon lists to make targeted cleanup practical
- reset bans and rarity overrides globally

It also includes run-level settings for:

- `Padding`
  Fill behavior when bans would otherwise leave a source short on valid picks.
- `Improve First N Boon Rarity`
  Forces the first several boon offers to roll at higher rarity.
- `Bridal Glow` target selection
  Lets you point that effect at a specific boon target where supported.

Use it when you want more control than broad god-pool filtering gives you:

- remove specific bad outcomes without deleting an entire source
- keep directed boon sources from offering dead options
- tighten a build around a smaller set of allowed traits
- preserve offer stability when aggressive bans would otherwise hollow out the pool

## Current Coverage

- `Olympians`
  Per-god boon bans and rarity controls.
- `Other Gods`
  Per-source boon bans and rarity controls for the non-Olympian pools tracked by the module.
- `Hammers`
  Per-hammer bans.
- `NPCs`
  Separate boon bans for underworld NPCs, surface NPCs, and keepsake-style sources.
- `Settings`
  Global padding, forced early rarity, and full reset actions.

## Installation

Install via [r2modman](https://thunderstore.io/c/hades-ii/) or manually place in your `ReturnOfModding/plugins` folder.

This module is usually installed as part of the full [Run Director modpack](https://github.com/h2pack-rundirector/run-director-modpack), where it appears in the shared Run Director UI with the other run-control modules.
