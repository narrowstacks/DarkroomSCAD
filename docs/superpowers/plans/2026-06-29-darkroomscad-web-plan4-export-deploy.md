# DarkroomSCAD Web — Plan 4: Export & Deploy

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users export the complete set of parts needed to print a working carrier (top + bottom, plus multi-material text parts when enabled) as a ZIP (default) or individual STLs, then deploy the site to Vercel sourcing the `.scad` from GitHub at a pinned ref.

**Architecture:** A pure part-enumeration function turns the current config into a list of candidate render jobs (each a `Top_or_Bottom`/`_WhichPart` override at final quality). An export controller renders each job through the existing `RenderClient`, **skips parts that render empty** (so we don't need exact SCAD part-model knowledge — e.g. text only on one half), and bundles the non-empty STLs with `fflate`. The build-time sync script gains a **GitHub-raw pinned-ref fetch** mode so Vercel builds pull the carrier source without a local checkout. No change to the Plan 1 render pipeline or the Plan 2/3 form/preview/theme contracts.

**Tech Stack:** Next.js 15, React 19, TypeScript, `fflate` (ZIP), Vitest, Vercel. Builds on Plans 1-3.

## Global Constraints

- **Repo:** all work in `~/workspace/darkroomscad-web` (`main`, remote `origin` = github.com/narrowstacks/darkroomscad-web). Push at the end of tasks the plan says to push.
- **No backend.** Export + render stay client-side WASM. The deployed site is effectively static (no serverless functions).
- **Reuse Plan 1-3; don't fork.** Consume `RenderClient.render(req)`, `RenderParams`/`RenderResult`, `useCarrierForm().toParams`, the worker (fresh-module-per-render). Do NOT change `render.ts` render args or the worker protocol.
- **Source of truth:** `Carrier_Type`/`Film_Format`/`Orientation`/`Top_or_Bottom`/`_WhichPart`/`Text_As_Separate_Parts`/`Enable_Owner_Name_Etch`/`Enable_Type_Name_Etch` are the params that define the printable parts (verified in the schema).
- **Export quality:** every export job sets `Render_Quality:"final"` (full `$fn`). Preview stays `"preview"`.
- **Empty-part skipping:** the render core throws on a degenerate/empty STL (`byteLength <= 84`). The export controller MUST catch that per-part and skip it (not abort the whole export) — this is how we avoid generating empty text STLs for a half that carries no text.
- **DarkroomSCAD source:** `github.com/narrowstacks/DarkroomSCAD` (PUBLIC); carrier at `negative-carriers/carrier.scad` + `negative-carriers/src/**`. The pinned ref defaults to a specific commit SHA (recorded in config), NOT a moving branch.
- **Deploy is an outward action.** The actual `vercel deploy` / project creation is USER-GATED — the implementer prepares everything and STOPS for the controller/user to run/confirm the deploy. Do not deploy autonomously.
- **Filenames:** parts named `<carrier>_<format>_<orientation>_<part>.stl` (spaces→`-`); ZIP named `<carrier>_<format>_carrier-set.zip`.

---

### Task 1: Part enumeration

Pure logic — full TDD. Turn the form's params into the candidate render jobs for a complete printable set.

**Files:**
- Create: `src/lib/export/part-enumeration.ts`
- Test: `src/lib/export/part-enumeration.test.ts`

**Interfaces:**
- Consumes: `RenderParams` from `@/lib/openscad/types`.
- Produces:
  - `interface PartJob { name: string; params: RenderParams }`
  - `function enumerateParts(form: RenderParams): PartJob[]`
  - Behavior: always both halves (`top`, `bottom`). When `Text_As_Separate_Parts !== true`: one `All` part per half. When `=== true`: a `Base` part per half, plus an `OwnerText` part (only if `Enable_Owner_Name_Etch === true`) and a `TypeText` part (only if `Enable_Type_Name_Etch === true`) per half. Every job sets `Render_Quality:"final"` and the `Top_or_Bottom`/`_WhichPart`/`Text_As_Separate_Parts` overrides. (The alignment board is in-geometry via the `Alignment_Board` param — NOT a separate job. Empty candidate parts are filtered later by the export controller, not here.)

- [ ] **Step 1: Write the failing tests**

Create `src/lib/export/part-enumeration.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { enumerateParts } from "./part-enumeration";
import type { RenderParams } from "../openscad/types";

const baseForm: RenderParams = {
  Carrier_Type: "omega-d", Film_Format: "35mm", Orientation: "vertical",
  Enable_Owner_Name_Etch: true, Enable_Type_Name_Etch: true,
};

describe("enumerateParts", () => {
  it("single-material: one All part per half (top + bottom), final quality", () => {
    const jobs = enumerateParts({ ...baseForm, Text_As_Separate_Parts: false });
    expect(jobs).toHaveLength(2);
    expect(jobs.map((j) => j.params.Top_or_Bottom)).toEqual(["top", "bottom"]);
    for (const j of jobs) {
      expect(j.params._WhichPart).toBe("All");
      expect(j.params.Render_Quality).toBe("final");
    }
    expect(jobs[0].name).toBe("omega-d_35mm_vertical_top.stl");
  });

  it("multi-material with both etches: Base + OwnerText + TypeText per half (6 jobs)", () => {
    const jobs = enumerateParts({ ...baseForm, Text_As_Separate_Parts: true });
    expect(jobs).toHaveLength(6);
    const whichParts = jobs.filter((j) => j.params.Top_or_Bottom === "top").map((j) => j.params._WhichPart);
    expect(whichParts).toEqual(["Base", "OwnerText", "TypeText"]);
    expect(jobs.find((j) => j.params._WhichPart === "OwnerText")!.name).toContain("owner-text");
  });

  it("multi-material with only the name etch: Base + OwnerText per half (4 jobs, no TypeText)", () => {
    const jobs = enumerateParts({
      ...baseForm, Text_As_Separate_Parts: true,
      Enable_Owner_Name_Etch: true, Enable_Type_Name_Etch: false,
    });
    expect(jobs).toHaveLength(4);
    expect(jobs.some((j) => j.params._WhichPart === "TypeText")).toBe(false);
  });

  it("encodes carrier/format/orientation/part in the filename, spaces dashed", () => {
    const jobs = enumerateParts({ ...baseForm, Film_Format: "6x6 filed", Text_As_Separate_Parts: false });
    expect(jobs[0].name).toBe("omega-d_6x6-filed_vertical_top.stl");
  });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `npm run test -- part-enumeration`
Expected: FAIL — not defined.

- [ ] **Step 3: Implement the enumeration**

Create `src/lib/export/part-enumeration.ts`:

```ts
import type { RenderParams } from "../openscad/types";

export interface PartJob {
  name: string;
  params: RenderParams;
}

function slug(s: string): string {
  return s.replace(/\s+/g, "-");
}

export function enumerateParts(form: RenderParams): PartJob[] {
  const carrier = slug(String(form.Carrier_Type ?? "carrier"));
  const format = slug(String(form.Film_Format ?? "format"));
  const orient = slug(String(form.Orientation ?? "vertical"));
  const multimat = form.Text_As_Separate_Parts === true;

  const job = (half: string, whichPart: string, suffix: string): PartJob => ({
    name: `${carrier}_${format}_${orient}_${half}${suffix}.stl`,
    params: {
      ...form,
      Top_or_Bottom: half,
      _WhichPart: whichPart,
      Text_As_Separate_Parts: multimat,
      Render_Quality: "final",
    },
  });

  const jobs: PartJob[] = [];
  for (const half of ["top", "bottom"]) {
    if (!multimat) {
      jobs.push(job(half, "All", ""));
    } else {
      jobs.push(job(half, "Base", "_base"));
      if (form.Enable_Owner_Name_Etch === true) jobs.push(job(half, "OwnerText", "_owner-text"));
      if (form.Enable_Type_Name_Etch === true) jobs.push(job(half, "TypeText", "_type-text"));
    }
  }
  return jobs;
}
```

- [ ] **Step 4: Run to verify pass**

Run: `npm run test -- part-enumeration`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add src/lib/export/part-enumeration.ts src/lib/export/part-enumeration.test.ts
git commit -m "feat(export): part enumeration (top/bottom, multi-material text parts)"
```

---

### Task 2: Export controller (multi-part render + ZIP)

Render each enumerated part, skip empties, bundle with `fflate`. The render-loop + zip-assembly + empty-skip are TDD'd against a fake render client.

**Files:**
- Modify: `package.json` (add `fflate`)
- Create: `src/lib/export/export-controller.ts`
- Test: `src/lib/export/export-controller.test.ts`

**Interfaces:**
- Consumes: `enumerateParts`/`PartJob`; a render-like client `{ render(req): Promise<RenderResult> }`; `fflate`.
- Produces:
  - `interface ExportProgress { done: number; total: number; current: string }`
  - `interface ExportedPart { name: string; stl: Uint8Array }`
  - `interface ExportResult { parts: ExportedPart[]; skipped: string[] }`
  - `async function renderParts(client, form, onProgress?): Promise<ExportResult>` — renders each `enumerateParts(form)` job sequentially at final quality; a job whose render throws the empty-STL error is added to `skipped` (NOT fatal); other errors propagate.
  - `function zipParts(parts: ExportedPart[]): Uint8Array` — `fflate.zipSync` of the parts by name.
  - `function isEmptyStlError(err: unknown): boolean` — matches the render core's degenerate-STL message.

- [ ] **Step 1: Install fflate**

```bash
cd ~/workspace/darkroomscad-web && npm install fflate
```

- [ ] **Step 2: Write the failing tests**

Create `src/lib/export/export-controller.test.ts`:

```ts
import { describe, it, expect, vi } from "vitest";
import { renderParts, zipParts } from "./export-controller";
import { unzipSync } from "fflate";
import type { RenderResult } from "../openscad/types";

const form = {
  Carrier_Type: "omega-d", Film_Format: "35mm", Orientation: "vertical",
  Text_As_Separate_Parts: false,
};
const ok = (stl: number[]): RenderResult => ({ stl: new Uint8Array(stl), log: "", durationMs: 1 });

describe("renderParts", () => {
  it("renders every part and reports progress", async () => {
    const render = vi.fn().mockResolvedValue(ok([1, 2, 3]));
    const seen: string[] = [];
    const result = await renderParts({ render }, form, (p) => seen.push(`${p.done}/${p.total}`));
    expect(render).toHaveBeenCalledTimes(2); // top + bottom
    expect(result.parts).toHaveLength(2);
    expect(result.skipped).toHaveLength(0);
    expect(seen[seen.length - 1]).toBe("2/2");
  });

  it("skips a part whose render is empty/degenerate (not fatal)", async () => {
    const render = vi.fn()
      .mockResolvedValueOnce(ok([1, 2, 3]))                                   // top OK
      .mockRejectedValueOnce(new Error("Render produced an empty (degenerate) STL.")); // bottom empty
    const result = await renderParts({ render }, form);
    expect(result.parts).toHaveLength(1);
    expect(result.skipped).toHaveLength(1);
  });

  it("propagates a non-empty render error (e.g. compile failure)", async () => {
    const render = vi.fn().mockRejectedValue(new Error("OpenSCAD exited with code 1."));
    await expect(renderParts({ render }, form)).rejects.toThrow(/code 1/);
  });
});

describe("zipParts", () => {
  it("bundles parts into a readable zip keyed by name", () => {
    const zip = zipParts([{ name: "a.stl", stl: new Uint8Array([1, 2]) }]);
    const back = unzipSync(zip);
    expect(Array.from(back["a.stl"])).toEqual([1, 2]);
  });
});
```

- [ ] **Step 3: Run to verify failure**

Run: `npm run test -- export-controller`
Expected: FAIL — not defined.

- [ ] **Step 4: Implement the controller**

Create `src/lib/export/export-controller.ts`:

```ts
import { zipSync } from "fflate";
import { enumerateParts } from "./part-enumeration";
import type { RenderParams, RenderResult } from "../openscad/types";

export interface ExportProgress { done: number; total: number; current: string }
export interface ExportedPart { name: string; stl: Uint8Array }
export interface ExportResult { parts: ExportedPart[]; skipped: string[] }

interface RenderLike {
  render(req: { params: RenderParams; quality: "preview" | "final" }): Promise<RenderResult>;
}

export function isEmptyStlError(err: unknown): boolean {
  return err instanceof Error && /empty \(degenerate\) STL|produced no output/i.test(err.message);
}

export async function renderParts(
  client: RenderLike,
  form: RenderParams,
  onProgress?: (p: ExportProgress) => void,
): Promise<ExportResult> {
  const jobs = enumerateParts(form);
  const parts: ExportedPart[] = [];
  const skipped: string[] = [];
  for (let i = 0; i < jobs.length; i++) {
    const job = jobs[i];
    onProgress?.({ done: i, total: jobs.length, current: job.name });
    try {
      const res = await client.render({ params: job.params, quality: "final" });
      parts.push({ name: job.name, stl: res.stl });
    } catch (err) {
      if (isEmptyStlError(err)) skipped.push(job.name);
      else throw err;
    }
  }
  onProgress?.({ done: jobs.length, total: jobs.length, current: "" });
  return { parts, skipped };
}

export function zipParts(parts: ExportedPart[]): Uint8Array {
  const entries: Record<string, Uint8Array> = {};
  for (const p of parts) entries[p.name] = p.stl;
  return zipSync(entries);
}
```

- [ ] **Step 5: Run to verify pass**

Run: `npm run test -- export-controller`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add package.json package-lock.json src/lib/export/export-controller.ts src/lib/export/export-controller.test.ts
git commit -m "feat(export): multi-part render controller with empty-skip + fflate zip"
```

---

### Task 3: Export panel UI + page integration (browser gate)

Replace the single "Download STL" bridge button with an export panel: **Download set (ZIP)** (default) and an individual-files mode. Browser-verified.

**Files:**
- Create: `src/components/ExportPanel.tsx`
- Modify: `src/app/page.tsx` (replace the download button with `<ExportPanel>`, wire the worker client + current params)

**Interfaces:**
- Consumes: `RenderClient`, `useCarrierForm().toParams`, `renderParts`/`zipParts`/`ExportProgress`.
- Produces: `ExportPanel({ client, getParams })` where `getParams(): RenderParams` returns the current full-quality form params (the page passes `() => toParams({})`).

- [ ] **Step 1: Build the export panel**

Create `src/components/ExportPanel.tsx`. Primary "Download set (ZIP)" + a disclosure for "Download individual files" that renders each part as it completes. Progress text from `onProgress`. Triggers downloads client-side.

```tsx
"use client";
import { useState } from "react";
import { renderParts, zipParts, type ExportProgress, type ExportedPart } from "@/lib/export/export-controller";
import type { RenderParams } from "@/lib/openscad/types";
import type { RenderClient } from "@/lib/openscad/client";

function download(name: string, data: Uint8Array, type: string) {
  const blob = new Blob([new Uint8Array(data)], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url; a.download = name; a.click();
  URL.revokeObjectURL(url);
}

export function ExportPanel({ client, getParams }: {
  client: () => RenderClient;
  getParams: () => RenderParams;
}) {
  const [busy, setBusy] = useState(false);
  const [progress, setProgress] = useState<ExportProgress | null>(null);
  const [individual, setIndividual] = useState(false);
  const [parts, setParts] = useState<ExportedPart[]>([]);
  const [error, setError] = useState<string | null>(null);

  async function run(): Promise<ExportedPart[] | null> {
    setBusy(true); setError(null); setParts([]);
    try {
      const form = getParams();
      const result = await renderParts(client(), form, setProgress);
      setParts(result.parts);
      return result.parts;
    } catch (e) {
      setError((e as Error).message);
      return null;
    } finally {
      setBusy(false); setProgress(null);
    }
  }

  async function handleZip() {
    const p = await run();
    if (!p || p.length === 0) return;
    const form = getParams();
    const zipName = `${String(form.Carrier_Type)}_${String(form.Film_Format)}_carrier-set.zip`.replace(/\s+/g, "-");
    download(zipName, zipParts(p), "application/zip");
  }

  return (
    <div className="mt-6 space-y-2">
      <button onClick={handleZip} disabled={busy}
        className="w-full rounded px-4 py-2.5 font-medium"
        style={{ background: "var(--primary)", color: "#08120b", opacity: busy ? 0.6 : 1 }}>
        {busy ? (progress ? `Rendering ${progress.done}/${progress.total}…` : "Rendering…") : "Download set (ZIP)"}
      </button>

      <button onClick={() => setIndividual((v) => !v)} className="text-sm underline"
        style={{ color: "var(--secondary)" }}>
        {individual ? "Hide individual files" : "Download individual files"}
      </button>

      {individual && (
        <div className="space-y-1">
          <button onClick={() => run()} disabled={busy}
            className="w-full rounded px-3 py-1.5 text-sm"
            style={{ background: "var(--surface-muted)", color: "var(--text)", border: "1px solid var(--border)" }}>
            Render all parts
          </button>
          {parts.map((p) => (
            <button key={p.name} onClick={() => download(p.name, p.stl, "model/stl")}
              className="flex w-full items-center justify-between rounded px-3 py-1.5 text-sm"
              style={{ background: "var(--surface)", color: "var(--text-muted)", border: "1px solid var(--border)" }}>
              <span>{p.name}</span><span style={{ color: "var(--primary)" }}>Download</span>
            </button>
          ))}
        </div>
      )}

      {error && <p className="text-sm" style={{ color: "var(--error)" }}>Export error: {error}</p>}
    </div>
  );
}
```

- [ ] **Step 2: Wire it into the page**

In `src/app/page.tsx`, replace the existing single "Download STL" button (and `handleDownload`) with `<ExportPanel client={getClient} getParams={() => toParams({})} />`, where `getClient` lazily returns the `RenderClient` (reuse the existing `clientRef` accessor used for preview, so export and preview share one worker). Keep the preview/viewer/theme wiring intact.

- [ ] **Step 3: tsc + build**

Run: `npx tsc --noEmit` (clean) and `npm run build` (compiles). `npm run test` all green.

- [ ] **Step 4: Manual browser verification (the gate — controller runs this)**

Run `npm run dev`. Load the page. Verify:
1. **Download set (ZIP)**: renders top + bottom (progress "1/2", "2/2"), downloads a `<carrier>_<format>_carrier-set.zip`. Open it — it contains both STL files; open one in a viewer to confirm it's a valid carrier half.
2. Enable **Separate text parts (multi-material)** (Advanced) → the ZIP now contains Base + text parts per half, and any half with no text is **skipped** (not an empty STL).
3. **Download individual files** → "Render all parts" lists each part; each downloads individually.
4. An invalid config (if reachable) surfaces a readable export error, not a silent failure.
Capture a screenshot of the export panel mid-render and the resulting ZIP contents.

- [ ] **Step 5: Commit + push**

```bash
git add src/components/ExportPanel.tsx src/app/page.tsx
git commit -m "feat(export): export panel — ZIP set (default) + individual files; wire into page"
git push origin main
```

---

### Task 4: Deferred polish (slider units + no-flash hardening)

The two carried-forward Minors from Plan 3.

**Files:**
- Modify: `src/lib/form/types.ts`, `src/lib/form/form-model.ts`, `src/config/carrier-ui.ts`, `src/components/controls/Field.tsx` (slider units)
- Modify: `src/lib/theme/themes.ts` (or a generated snippet), `src/app/layout.tsx` (no-flash full vars)

**Interfaces:**
- `FieldConfig`/`ResolvedField` gain `unit?: string`; `resolveFormModel` passes it through; `Field` passes `field.unit` to `Slider`.

- [ ] **Step 1: Slider units**

Add `unit?: string` to `FieldConfig` and `ResolvedField` (`types.ts`); in `resolveFormModel` add `unit: fc.unit`; in `Field.tsx`'s `slider` case change `unit={undefined}` → `unit={field.unit}`. In `carrier-ui.ts`, add `unit: "mm"` to the dimensional sliders (`Custom_Film_Width/Height`, `Custom_Opening_Width/Height`, `TEXT_ETCH_DEPTH`, the four `*_Offset`, `Peg_Gap`, `Adjust_Film_Width/Height`, `Layer_Height_mm`) — NOT `Font_Size` (use `"pt"` or leave unitless per taste) or `Text_Layer_Multiple` (count). Add one form-model test asserting `unit` resolves from the overlay.

Run: `npm run test -- form-model` and confirm a slider shows its unit in the browser later.

- [ ] **Step 2: No-flash full-var hardening**

Make the inline `<head>` script in `layout.tsx` apply the FULL var set for the resolved theme before paint (not just `data-theme`), eliminating the brief flash for users with a persisted non-dark theme. Inline a minimal token table into the script as a JSON literal generated from `THEMES` (keep it in sync — e.g. import `THEMES` server-side and `JSON.stringify` the `{name: vars}` map into the script string). The script: read stored/`matchMedia` theme → set `data-theme` AND loop the theme's vars via `documentElement.style.setProperty`. `ThemeProvider`'s effect still runs (idempotent).

Run: `npm run build`; verify in the browser later (persisted light theme → no dark flash on reload).

- [ ] **Step 3: Verify + commit**

`npm run test` green, `npx tsc --noEmit` clean, `npm run build` compiles.

```bash
git add src/lib/form src/config/carrier-ui.ts src/components/controls/Field.tsx src/lib/theme/themes.ts src/app/layout.tsx
git commit -m "polish: slider units (mm) + full-var no-flash theme script"
```

---

### Task 5: Vercel deploy — GitHub-raw pinned source + deploy prep

Make the build self-sufficient on Vercel (no local DarkroomSCAD checkout) by fetching the carrier source from GitHub at a pinned ref, then prepare the Vercel deploy. **The actual deploy is USER-GATED — prepare and STOP.**

**Files:**
- Modify: `scripts/sync-scad.ts` (add a GitHub-raw fetch mode)
- Create: `scripts/scad-source.config.json` (the pinned ref) — or env `DARKROOMSCAD_REF`
- Modify: `README.md` (deploy notes)

**Interfaces:**
- `sync-scad.ts`: when no `--local <path>` is given AND `../DarkroomSCAD` is absent, fetch from GitHub: list `.scad` files under `negative-carriers/` via the GitHub trees API at the pinned ref, fetch each via `raw.githubusercontent.com`, then proceed exactly as the local path (write `public/scad/**`, parse the schema, write the manifest). The committed `public/scad/**` remains a fallback if the fetch fails (log + use existing).

- [ ] **Step 1: Add the GitHub-raw fetch mode to sync-scad.ts**

Pin the ref: create `scripts/scad-source.config.json`:
```json
{ "repo": "narrowstacks/DarkroomSCAD", "ref": "<PIN A COMMIT SHA HERE>", "subdir": "negative-carriers" }
```
(Record the current `main` SHA of `narrowstacks/DarkroomSCAD` — get it with `gh api repos/narrowstacks/DarkroomSCAD/commits/main --jq .sha`. Pin the SHA, not `main`, for reproducible builds.)

In `resolveSource()` / `main()`: if `--local` is absent and `../DarkroomSCAD/negative-carriers/carrier.scad` does not exist, switch to GitHub mode:
- `GET https://api.github.com/repos/<repo>/git/trees/<ref>?recursive=1` → filter paths under `<subdir>/` ending in `.scad`.
- For each, `GET https://raw.githubusercontent.com/<repo>/<ref>/<path>` → write to `public/scad/<path-relative-to-subdir>`.
- Parse `carrier.scad` → schema; write manifest (same as local mode).
- On any fetch error: `console.warn` and fall back to the already-committed `public/scad/**` (do NOT throw — Vercel build must not fail on a transient GitHub hiccup when usable artifacts exist).

Keep `collectScadFiles` + the local path mode unchanged (dev still uses `--local ../DarkroomSCAD`). Add a unit test for the GitHub path-filtering helper (pure: given a trees-API response, returns the `.scad` paths under the subdir) — do NOT hit the network in tests.

- [ ] **Step 2: Verify the build is self-sufficient**

From a state where `../DarkroomSCAD` is reachable, `npm run sync:scad` still works (local mode). Then simulate CI: temporarily rename/point away from the local source and run `npm run sync:scad` — it fetches from GitHub at the pinned ref and writes `public/scad/**` + the schema + manifest. Confirm `npm run build` succeeds end-to-end. Run `npm run test` (incl. the new path-filter test) green; `npx tsc --noEmit` clean.

- [ ] **Step 3: Prepare the Vercel deploy (do NOT deploy yet)**

- Confirm `next.config.ts`'s COOP/COEP headers are present (the WASM worker needs cross-origin isolation) — these apply on Vercel via Next headers.
- Confirm the build outputs a static-servable app (no serverless functions required); the 9.6MB `openscad.wasm` + assets are static `public/` files Vercel serves directly.
- Add deploy notes to `README.md`: the pinned-ref source model, the COOP/COEP requirement, and how to bump the source ref.
- Commit the deploy-readiness changes and push.
- **STOP and hand off to the controller/user for the actual deploy.** Report that the project is deploy-ready and what the deploy command will be (`vercel` / the Vercel deploy flow), noting it publishes the site and needs the user's go-ahead.

```bash
git add scripts/sync-scad.ts scripts/scad-source.config.json README.md
git commit -m "feat(build): GitHub-raw pinned-ref source fetch for CI/Vercel; deploy readiness"
git push origin main
```

- [ ] **Step 4: (Controller/user-gated) Deploy to Vercel + smoke test**

After user confirmation: deploy via Vercel (CLI `vercel` or the Vercel deploy flow), set any needed config, and smoke-test the production URL:
1. The page loads; the customizer renders.
2. A preview render completes (WASM works behind the COOP/COEP headers on Vercel).
3. The export ZIP downloads.
If the production WASM render fails on headers, verify the COOP/COEP response headers are actually present on the deployed `/wasm/*` and document the fix.

---

## Plan 4 Self-Review

- **Spec coverage:** complete-set export as ZIP (default) OR individual files, user's choice (Tasks 1-3) ✓; part enumeration incl. multi-material text parts, alignment board as in-geometry, empty-part skipping (Tasks 1-2) ✓; meaningful filenames (Task 1) ✓; the Plan 3 deferred polish — slider units + no-flash hardening (Task 4) ✓; Vercel deploy with the spec's GitHub-raw pinned-ref source model + the `prebuild` CI fix (Task 5) ✓; deploy is user-gated (Global Constraints + Task 5 Step 3) ✓.
- **Placeholder scan:** complete code for the testable logic (enumeration, controller, zip). The two genuine unknowns are honestly handled, not hand-waved: (a) which half(s) carry text is resolved at runtime by **skipping empty renders** (Task 2) rather than guessing the SCAD; (b) the pinned source SHA is a literal the implementer fills from `gh api` (Task 5 Step 1).
- **Type consistency:** `PartJob` (Task 1) consumed by `renderParts` (Task 2). `ExportedPart`/`ExportProgress`/`ExportResult` defined in Task 2, consumed by `ExportPanel` (Task 3). Reuses Plan 1 `RenderParams`/`RenderResult`/`RenderClient` and Plan 2 `toParams` unchanged. `unit?` added once to the form types (Task 4) and threaded through resolver→Field→Slider.

## Notes for the executor

- **Empty-part skipping is load-bearing**, not an optimization: the carrier likely etches text on only one face, so `OwnerText`/`TypeText` for the other half render empty. The controller catches the render core's degenerate-STL error per part and skips it; only a *non-empty* error (compile failure) aborts the export. Verify the skip path in the browser by enabling multi-material text.
- **Export shares the preview worker.** Don't spin up a second worker for export — reuse the page's `RenderClient` (the worker serializes renders, so export jobs queue behind any in-flight preview). Full-quality export renders are slower (~seconds each); the progress UI covers that.
- **Pin the source SHA, not `main`.** A moving `main` makes Vercel builds non-reproducible and can silently change the deployed carrier. Bumping the carrier design = update the SHA in `scad-source.config.json` deliberately.
- **Deploy publishes the site.** Do not run the actual Vercel deploy without the user's explicit go-ahead.
