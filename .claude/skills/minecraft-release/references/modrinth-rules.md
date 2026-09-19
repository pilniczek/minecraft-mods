# Modrinth rules, mapped to this repository

Five legal pages govern a published project. Read this file before a first submit, before changing a project title or summary, and before adding any image to a project page.

| Page | Last modified | What it binds |
| --- | --- | --- |
| `https://modrinth.com/legal/rules` | 2026-08-13 | Every project, version and page. The only page with per-project obligations. |
| `https://modrinth.com/legal/terms` | 2026-08-13 | Account and API use. Incorporates the content rules. |
| `https://modrinth.com/legal/copyright` | DMCA procedure | What happens after a rights complaint. |
| `https://modrinth.com/legal/security` | 2026-03 | How to report a vulnerability in Modrinth itself. |
| `https://modrinth.com/legal/privacy` | 2023-11-17 | What Modrinth collects from creators and players. |

Dates move. Re-read the rules page rather than trusting this summary when a review comes back rejected.

## 1. Prohibited content

None of the twelve prohibitions bites a block mod, with three worth checking every release:

- No uploading data to a remote server the player did not choose to connect to, without clear disclosure. A block mod sends nothing, so this stays clean only while no networking code appears.
- No bypassing Mojang's server-joining restrictions.
- No implying endorsement by Modrinth, Mojang or Microsoft. Keep those names out of the project title, icon and summary.

## 2. Clear and honest function

The project description must state three things, and a reviewer checks for all three:

1. what the project specifically does or adds
2. why someone should want to download it
3. any critical information needed before downloading

For this repository the third item is: Java Edition with Fabric only, Fabric API required, and the Bedrock addon lives on GitHub rather than Modrinth.

Accessibility rules that reject descriptions: every description needs a plain-text version, needs an English translation, and must not use headers as body text. Images and video may lead, but cannot be the only content.

## 3. Cheats and hacks

Out of scope for building and decorative blocks. It applies to x-ray, aim assist, flight, movement changes, assisted combat, item duplication and client-side hiding of other mods.

## 4. Copyright and reuploads

Ship only what the uploader has the rights to. Credit every source that someone else authored, in a meaningful way rather than a passing mention.

Two live cases here:

- **Textures.** A texture derived from a third party's artwork or photo needs a license permitting redistribution, plus credit. The same PNG ships in the jar and in the Bedrock resource pack, so one bad asset contaminates both deliverables.
- **Fabric API.** Apache-2.0 permits redistribution, but Modrinth requires third-party mods to be declared, not bundled. A mod project declares the dependency. The `.mrpack` this repository builds bundles it under `overrides/mods/`, which is why that file goes to a GitHub release rather than a Modrinth modpack project.

A rights complaint runs through the DMCA process at `dmca@modrinth.com`. Filing a counter notice means handing over a postal address and consenting to US federal jurisdiction, so verify an asset before publishing rather than after a notice. Repeat infringers lose the whole account, not the one project.

## 5. Metadata

Enforced loosely, but each one is a review round trip:

| Requirement | What it means here |
| --- | --- |
| Metadata consistent everywhere | Project title, license, environment and tags must agree with `fabric.mod.json`, `LICENSE` and the READMEs. |
| Title is the project name alone | No version number, no loader name, no tagline, and no slug spelling. `Custom Blocks`, not `custom-blocks`. |
| Summary does not repeat the title | And carries no formatting. |
| External links are public and relevant | The source link must point at a repository anyone can open. |
| Gallery images represent the project | No screenshot of something the mod does not do. |
| Dependencies listed on every version | `required.project 'fabric-api'` in `gradle/mod-conventions.gradle` satisfies this. |
| Additional files only for special purposes | A sources jar qualifies. Anything with different functionality is a separate project. |
| Uploaded files relate to the project | The `.mrpack` is a different deliverable, so it never becomes a version of the mod project. |
| Content disclosures accurate and current | See below. |

## 6. Generative AI

The rule that most often applies to work done with an agent, and the one with a flat prohibition in it.

**Disclosure is required** when any of these is true:

- a substantial portion of the code is AI output
- any shipped asset is primarily or entirely AI output
- the design or functionality relies on generative AI at runtime
- any part of the project page, description included, relies on generative AI

Code and documentation written with an agent trigger the first and fourth bullets, so the "Contains AI-generated content" disclosure belongs on every project in this repository. It is not a judgement call.

**Prohibited outright:**

- No image created or derived from generative AI may be uploaded as an icon, a gallery image, or anywhere else on a project page. Such images get removed. A texture inside the jar is not part of the project page, so it is disclosed rather than banned; the same PNG used as the project icon is banned.
- A project may not be published publicly if its contents are primarily or entirely AI output. Human contribution has to be primary and significant: design decisions, block properties, recipe design, in-game verification.

## Content disclosures

Ten exist. Enable the ones that apply, keep them current, and leave the rest off.

| Disclosure | Applies to a block mod when |
| --- | --- |
| AI-generated content (code, assets, text) | Any of the section 6 triggers is met. Normally yes for this repository. |
| AI functionality | The mod calls a generative model at runtime. Not the case here. |
| Advertisements | The mod itself promotes another work. |
| Paid features | Something unlocks with real money. |
| Telemetry | The mod collects usage data or sends data to a third party, with the consent model named: opt-in, opt-out or always-on. A block mod that sends nothing leaves this off; Modrinth's own download and playtime tracking is never the creator's disclosure. |
| Derivative content | Crediting an upstream work, a fork, or a license that requires public attribution. |
| Photosensitivity warning | Flashing over 25% of the screen, faster than 3 times per second, or longer than 5 seconds. |
| External system interactions | Reading, writing or modifying files outside normal gameplay. |
| Archive status | The project is no longer maintained. |

## Terms of use and privacy, in one line each

- The service is for personal, non-commercial use; monetisation runs through the Rewards Program, which is opt-in.
- The API license covers Minotaur's uploads and requires compliance with the content rules.
- Data on Modrinth may not be used to train models.
- Publishing links the account's username, display name and profile picture to the project publicly.
- Records are kept indefinitely; erasure is requested at `gdpr@modrinth.com` with a 30-day response. View and download records anonymise after 24 months.

## Reporting a vulnerability in Modrinth

Mail `support@modrinth.com` with the affected page or repository, a description, and non-destructive reproduction details. Do not open a GitHub issue. Volumetric attacks and missing-header reports are out of scope.
