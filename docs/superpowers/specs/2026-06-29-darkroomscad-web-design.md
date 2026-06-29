# DarkroomSCAD Web — Design Spec

**Date:** 2026-06-29
**Status:** Approved (brainstorming complete; next step: implementation plan)
**Author:** Aaron + Claude

## Summary

A standalone website that lets analog photographers configure and export 3D-printable
negative carriers from the DarkroomSCAD parametric models — without touching code. Users
pick their enlarger, film format, name/text, font, and options through a guided form, see a
live 3D preview, and download print-ready STL files. The site runs OpenSCAD entirely in the
browser via WebAssembly and deploys to Vercel as an effectively static app (no backend, no
per-render server cost).

This lives in a **new, separate repository** (`darkroomscad-web`) that pulls `.scad` source
from the DarkroomSCAD repo at a pinned ref. This spec document is committed to the
DarkroomSCAD repo as the planning artifact of record.

## Goals

- Non-technical photographers can produce a working carrier STL set in a few clicks.
- Live, interactive 3D preview that updates as parameters change.
- Export the complete set of parts needed to print a real carrier (top + bottom +
  alignment board + multi-material text parts as applicable).
- Visual design that feels like a sibling to [dorkroom](https://dorkroom.art).
- Architecture extensible to other DarkroomSCAD product families (lens boards, Paterson
  tank, thermometer holder) later — but ship **negative carriers only** first.

## Non-Goals (v1)

- No in-browser code editor / SCAD source editing (guided customizer only).
- No product families beyond negative carriers (architect for extension; don't build yet).
- No server-side / serverless rendering (explicitly rejected — see Decisions).
- No user accounts, saved configs server-side, or e-commerce.

## Key Decisions (from brainstorming)

| Decision | Choice | Rationale |
|---|---|---|
| UX model | **Guided customizer** (no code editor) | Audience is photographers, not coders; product feel |
| Catalog scope | **Negative carriers only**, extensible | Most complex/used design; ship focused |
| 3D preview | **Live in-browser preview** | Best product feel; WASM makes it free/client-side |
| File sync | **Build-time fetch/copy script** | Reproducible, pinned, separate repos stay decoupled |
| Export unit | **ZIP (default) or individual files, user choice** | ZIP matches how carriers are actually printed |
| Rendering | **Fully client-side WASM** (Approach A) | No backend, infinite scale, zero render cost |
| Engine (v1) | **scadder fast-csg build**; Manifold deferred | Importable/Node-testable; text rendering proven |
| Framework | **Next.js (App Router) on Vercel** | Native Vercel fit; match dorkroom's *look*, not its stack |

### Rejected approaches

- **Serverless rendering (Approach B):** native OpenSCAD in Vercel functions → cold starts,
  function timeouts on large (4x5) renders, per-render cost. Loses the static-site advantage.
- **Fork openscad-playground (Approach C):** architected around a Monaco editor + PrimeReact,
  fights the clean guided-form UX. Used only as a *reference* for known-good WASM/font setup.

## Architecture

### 1. Repo & stack

New repo `darkroomscad-web`:

- **Next.js (App Router) + TypeScript**, deployed on Vercel (effectively static).
- **react-three-fiber + drei** — 3D viewer.
- **fflate** — client-side ZIP.
- **Tailwind CSS** — styling, with a custom theme mirroring dorkroom's tokens.
- **openscad-wasm** (pinned release) — OpenSCAD in a Web Worker.
- All OpenSCAD execution is client-side in a Web Worker. No backend.

### 2. File-sync & build pipeline

`scripts/sync-scad.ts`, run at build time:

- Fetches `carrier.scad` + `src/**` from the DarkroomSCAD repo at a **pinned ref**
  (`DARKROOMSCAD_REF` env var, default a tag/commit SHA). Supports `--local ../DarkroomSCAD`
  for local dev against a working tree.
- Writes the SCAD tree into `public/scad/` (mounted into the WASM virtual filesystem).
- Parses `carrier.scad`'s customizer annotations (`/* [Section] */`, `// [opt,opt]` dropdowns,
  numeric ranges, defaults, comments-as-help) into `generated/param-schema.json`.

Pinning the ref makes builds reproducible; updating the design is a deliberate ref bump.

### 3. Parameter system (auto-parse + curation overlay)

Two layers keep the form both in-sync and clean:

- **`generated/param-schema.json`** — raw truth, auto-derived from `carrier.scad`.
- **`config/carrier-ui.ts`** — hand-maintained curation overlay controlling:
  - Which params are exposed vs. hidden (e.g. hide `TEXT_ETCH_OVEREXTRUDE`; tuck raw text
    offsets behind an "Advanced" disclosure).
  - Friendly labels, help text, grouping, order, step sizes.
  - **Fonts:** replace the free-text `Fontface` param with a dropdown of **bundled open
    fonts only** (we can only render fonts mounted into the WASM FS). The DarkroomSCAD default
    `Lucida Console` is proprietary and must be remapped to a bundled font (e.g. a Liberation
    or DejaVu mono).
  - Conditional visibility: Custom Film Format fields only when `Film_Format=="custom"`;
    `Alignment_Board_Type` only when `Alignment_Board==true`; etc.

A **build-time consistency check** fails the build if the overlay references a param that no
longer exists in the generated schema — so renaming a parameter in the SCAD source can't
silently break the site.

### 4. WASM render engine

`lib/openscad/worker.ts` — a Web Worker wrapping a **pinned `openscad-wasm` release**
(manifold backend; must be a `textmetrics`-capable, nightly-tracking build). On init it mounts
a virtual filesystem containing:

- The synced SCAD tree (`carrier.scad` as the main file, `src/` relative to it).
- **BOSL2** (pinned version) on the OpenSCAD library path.
- **Bundled fonts** + fontconfig so `text()` and `textmetrics()` resolve.

Render API:

```ts
render({ params, quality, part }) -> { stl: Uint8Array, log: string, durationMs: number }
```

- Parameters passed via a written **params JSON** (OpenSCAD customizer parameter set,
  `-p params.json -P set`) for robust escaping of names/strings.
- Manifold backend; `quality` maps to `Render_Quality` + `$fn`.
- Worker **serializes** renders and supports **cancellation** (newest request wins / debounced).

### 5. Preview & viewer

- On parameter change (debounced ~400ms): request a **fast preview** render
  (`Render_Quality="preview"`, low `$fn`, single representative part).
- Resulting STL streams into a **react-three-fiber** viewer: orbit/zoom, grid, auto-fit,
  themed materials.
- A subtle "preview quality" badge. Full-quality renders happen at export time.
- WASM load + first render show a friendly progress state.

### 6. Export

Export panel offers **ZIP (default)** or **individual files**:

- **ZIP:** enumerate the parts needed from the current config — top, bottom, alignment board
  (if enabled), separate text parts (if multi-material enabled) — run a **full-quality render
  per part** (with appropriate `Top_or_Bottom` / `_WhichPart` overrides), name each
  meaningfully (e.g. `omega-d_35mm_vertical_top.stl`), and bundle via fflate with progress.
- **Individual:** pick a single part, download one STL.
- Filenames encode carrier type / film format / orientation / part.

### 7. Error handling

- OpenSCAD compile/render errors (e.g. invalid custom dimensions) are caught in the worker
  and surfaced as readable inline messages — **never a silent empty download**.
- WASM-load failure shows an explicit fallback message (with browser/WebAssembly guidance).
- Empty/degenerate geometry (zero-size STL) is detected and reported rather than exported.

### 8. Visual direction (aligned to dorkroom)

Adopt dorkroom's design language so the two read as a family. (Match the *look and theme
tokens*, not its Vite/TanStack framework — we stay on Next.js for Vercel fit.)

- **Typography:** `Fraunces` (variable serif) for display/headings, `Montserrat` (variable
  sans) for UI/body.
- **Theme system with parity** via CSS custom properties + a theme toggle:
  - **Dark (default):** bg `#09090b`, surfaces `#121214` / `#1c1c1f`; accents mint
    `#6ef3a4` (primary), sky `#7dd6ff`, coral `#f99f96`, lime `#e5ff7d`; text
    `#ffffff` → `#e4e4e7` → `#a1a1aa` → `#71717a`; borders `rgba(255,255,255,0.2|0.1|0.05)`.
  - **Light:** bg `#ffffff`, surfaces `#f8f9fa` / `#f1f3f4`; accents `#2d7a4a`, `#1e6091`,
    `#c4524a`, `#8b9c2e`.
  - **Darkroom safelight:** pure black `#000000`, red-only palette
    (`#ff0000` / `#a90000` / `#920000` / `#820000`) — usable under a safelight.
  - **High-contrast** (e-ink friendly).
- **Semantic colors:** success = mint, warning = lime, error = coral, info = sky — reused for
  render status and error messages.
- **3D viewer:** map materials to theme visualization tokens (model `#666`, grid/edges
  `#353535`, overlay `rgba(0,0,0,0.5)`) so the preview sits in the palette.
- **Component feel:** dorkroom's calculator aesthetic — clean surface cards, subtle
  white-alpha borders, gradient accent cards for primary actions/sections.

### 9. Testing

- **Unit:** customizer-annotation parser (deterministic fixtures); schema/overlay
  consistency check.
- **Integration (headless):** worker renders a known config → assert a non-empty, valid STL;
  one render per carrier type as a smoke test.
- **E2E (later):** Playwright happy path (configure → preview → export ZIP).

## Open Risks (validate early in implementation; not design blockers)

1. **`textmetrics` in WASM:** the chosen `openscad-wasm` release must have `textmetrics`
   enabled, or the carrier's text centering breaks. Fallback: a small JS metrics shim that
   computes centering offsets and passes them as params. Validate before deep UI work.
2. **BOSL2 + nightly features in the WASM build:** confirm the carrier renders end-to-end
   (BOSL2 attachables, etc.) in the pinned build.
3. **Font fidelity:** centering via `textmetrics` depends on the *actual rendered font*;
   ensure the bundled font used for metrics is the one used for geometry.

## Future Extensions (out of scope for v1)

- Additional product families (lens boards, Paterson tank, thermometer holder) via the same
  schema + overlay + worker pipeline — each gets its own main `.scad` and UI overlay.
- Shareable config URLs (encode params in the hash/query).
- PWA / offline support.

> **Update 2026-06-29 (implementation):** v1 ships on the **scadder** OpenSCAD-WASM build (CGAL
> **fast-csg**, importable factory). **Manifold deferred** — no importable Manifold build exists
> prebuilt, and building from source hit a chain of upstream breakages. The textmetrics risk
> (Open Risk #1) is **RETIRED**: text rendering verified working on fast-csg. See the plan's
> "Amendment — 2026-06-29" for details and the deferred Manifold-upgrade task.
