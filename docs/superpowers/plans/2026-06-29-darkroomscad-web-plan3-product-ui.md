# DarkroomSCAD Web — Plan 3: Product UI (Friendly Controls + Theming)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reshape the customizer from an OpenSCAD-customizer port (dropdowns, checkboxes, number fields) into a friendly web product — segmented buttons, toggle switches, sliders, enlarger cards, and a signature **film-format picker** whose chips show each format's true frame proportions — and add a full theme system (dark / light / darkroom-safelight / high-contrast) with a toggle.

**Architecture:** Extend the Plan 2 control model with new control kinds and a small kit of presentational components; add one bespoke `FilmFormatPicker` for the signature. The curation overlay (`carrier-ui.ts`) is rewritten to assign each field a friendly control. A theme system stores tokens as TS objects (single source of truth), applies them as CSS custom properties, and exposes 3D-viewer colors to the viewer so it follows the theme. No change to the render pipeline (Plan 1) or the form-state/preview contracts (Plan 2).

**Tech Stack:** Next.js 15 (App Router), React 19, Tailwind v4, TypeScript, Vitest. Builds on Plan 1 (Manifold WASM render core) + Plan 2 (schema-driven form, preview controller, r3f viewer).

## Global Constraints

- **Repo:** all work in `~/workspace/darkroomscad-web` (`main`, remote `origin` = github.com/narrowstacks/darkroomscad-web). Push at the end of each task that the plan says to push.
- **No backend.** Client-side WASM only; app stays effectively static.
- **Reuse Plan 1/2; don't fork.** Consume `resolveFormModel`/`ResolvedField`/`ControlKind` (`src/lib/form/`), `useCarrierForm`, `PreviewController`, `RenderClient`, `StlViewer`, `parseBinaryStl`, `generated/param-schema.json`, `BUNDLED_FONTS`. Do NOT change `render.ts`/`worker.ts` render args or the worker protocol.
- **Schema is the source of truth.** Every control still binds to a real schema param; the overlay consistency test (`carrier-ui.test.ts`) must keep passing. The `FilmFormatPicker` may only ever produce `Film_Format` values that exist in the schema's enum — guard this with a test.
- **`Render_Quality` stays system-managed** (preview vs final); never a user control.
- **Visual language (dorkroom-aligned):** Fraunces (display) + Montserrat (UI); numeric readouts use `font-variant-numeric: tabular-nums`. Accent semantics unchanged: primary = mint `#6ef3a4`, error = coral `#f99f96`.
- **Themes (exact token sets in Task 4):** `dark` (default), `light`, `darkroom` (red-on-black safelight), `high-contrast`. Theme persists in `localStorage` (`darkroomscad-theme`); initial theme respects `prefers-color-scheme` when unset. No flash of wrong theme on load.
- **Deferred to Plan 4 (do NOT build here):** ZIP / multi-part export + part enumeration; Vercel deploy + the `prebuild` CI fix (GitHub-raw pinned fetch). Plan 3 keeps the single-STL "Download" button from Plan 2.
- **Accessibility floor:** every control keyboard-operable with a visible focus ring; toggles use `role="switch"`/`aria-checked`; segmented groups use real `<button>`s with `aria-pressed`; sliders are native `<input type=range>` with a visible value; respect `prefers-reduced-motion`.

## Design Direction (the signature)

- **Film-format chips** are the page's memorable element: each chip draws a frame at the format's true aspect ratio (35mm 3:2, 6×6 1:1, 6×7 5:4, 4×5 5:4, …) so the control *looks like the thing it selects*. The 16 raw schema formats collapse to ~8 base chips + a **"filed edges"** toggle (maps `X` → `X filed`) + a **Custom** chip that reveals the dimension sliders. This is one place to spend boldness; keep all other controls quiet.
- **Enlarger cards** carry the second on-subject visual: each card shows an SVG **silhouette of that carrier's general outline** (outer body only, no film opening), generated from the real geometry. Two quiet, accurate glyphs — the film frame and the carrier body — not decoration.
- Everything else is a disciplined control kit: **segmented** button groups (orientation, part, pegs, board type, type-label source), **switches** (etch name, etch type, alignment board, flip, separate text parts), **sliders** (font size, offsets, gaps, dimensions), **cards** (enlarger).

---

### Task 1: Control-kit primitives (Segmented, Switch, Slider, CardSelect)

Add the friendly controls and wire `Field` to dispatch to them. Value-coercion logic is TDD'd; the visuals are browser-verified in Task 5.

**Files:**
- Modify: `src/lib/form/types.ts` (extend `ControlKind`)
- Create: `src/lib/form/control-value.ts` (shared option-value coercion + slider clamp)
- Test: `src/lib/form/control-value.test.ts`
- Create: `src/components/controls/Segmented.tsx`, `Switch.tsx`, `Slider.tsx`, `CardSelect.tsx`
- Modify: `src/components/controls/Field.tsx` (dispatch to the new kinds)

**Interfaces:**
- Produces:
  - `type ControlKind = "select" | "number" | "text" | "toggle" | "segmented" | "switch" | "slider" | "cards"`
  - `function coerceOptionValue(options: { value: string | number; label: string }[] | undefined, raw: string): string | number` — maps a selected control's string back to the typed option value (numbers stay numbers).
  - `function clampSlider(value: number, min?: number, max?: number): number`
  - `Segmented(props: { options; value; onChange; label; ariaLabel })`, `Switch(props: { checked; onChange; label; help? })`, `Slider(props: { value; min?; max?; step?; onChange; label; unit? })`, `CardSelect(props: { options; value; onChange; label })`

- [ ] **Step 1: Write the failing test for control-value helpers**

Create `src/lib/form/control-value.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { coerceOptionValue, clampSlider } from "./control-value";

describe("coerceOptionValue", () => {
  it("returns the typed (number) value for a matching numeric option", () => {
    const opts = [{ value: 1, label: "One" }, { value: 2, label: "Two" }];
    expect(coerceOptionValue(opts, "2")).toBe(2);
    expect(typeof coerceOptionValue(opts, "2")).toBe("number");
  });
  it("returns the string value for a matching string option", () => {
    const opts = [{ value: "omega-d", label: "Omega" }];
    expect(coerceOptionValue(opts, "omega-d")).toBe("omega-d");
  });
  it("falls back to the raw string when there are no options", () => {
    expect(coerceOptionValue(undefined, "x")).toBe("x");
  });
});

describe("clampSlider", () => {
  it("clamps to min and max when provided", () => {
    expect(clampSlider(5, 0, 10)).toBe(5);
    expect(clampSlider(-3, 0, 10)).toBe(0);
    expect(clampSlider(99, 0, 10)).toBe(10);
  });
  it("passes through when bounds are absent", () => {
    expect(clampSlider(42)).toBe(42);
  });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `npm run test -- control-value`
Expected: FAIL — not defined.

- [ ] **Step 3: Implement the helpers + extend ControlKind**

In `src/lib/form/types.ts`, replace the `ControlKind` definition with:

```ts
export type ControlKind =
  | "select" | "number" | "text" | "toggle"
  | "segmented" | "switch" | "slider" | "cards";
```

Create `src/lib/form/control-value.ts`:

```ts
export function coerceOptionValue(
  options: { value: string | number; label: string }[] | undefined,
  raw: string,
): string | number {
  const opt = options?.find((o) => String(o.value) === raw);
  return opt ? opt.value : raw;
}

export function clampSlider(value: number, min?: number, max?: number): number {
  let v = value;
  if (min !== undefined && v < min) v = min;
  if (max !== undefined && v > max) v = max;
  return v;
}
```

- [ ] **Step 4: Run to verify pass**

Run: `npm run test -- control-value`
Expected: PASS.

- [ ] **Step 5: Build the four primitives**

Create `src/components/controls/Segmented.tsx`:

```tsx
"use client";
import { coerceOptionValue } from "@/lib/form/control-value";
import type { FormValue } from "@/lib/form/types";

export function Segmented({ options, value, onChange, label, ariaLabel }: {
  options: { value: string | number; label: string }[];
  value: FormValue;
  onChange: (v: FormValue) => void;
  label: string;
  ariaLabel?: string;
}) {
  return (
    <div className="py-1">
      <span className="block text-sm font-medium mb-1" style={{ color: "var(--text)" }}>{label}</span>
      <div role="group" aria-label={ariaLabel ?? label}
        className="inline-flex flex-wrap gap-1 rounded-lg p-1"
        style={{ background: "var(--surface-muted)", border: "1px solid var(--border)" }}>
        {options.map((o) => {
          const selected = String(o.value) === String(value);
          return (
            <button key={String(o.value)} type="button" aria-pressed={selected}
              onClick={() => onChange(coerceOptionValue(options, String(o.value)))}
              className="rounded-md px-3 py-1.5 text-sm transition-colors focus-visible:outline-2"
              style={selected
                ? { background: "var(--primary)", color: "#08120b", fontWeight: 600 }
                : { color: "var(--text-muted)" }}>
              {o.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
```

Create `src/components/controls/Switch.tsx`:

```tsx
"use client";

export function Switch({ checked, onChange, label, help }: {
  checked: boolean;
  onChange: (v: boolean) => void;
  label: string;
  help?: string;
}) {
  return (
    <div className="flex items-center justify-between gap-3 py-1.5">
      <div>
        <span className="text-sm font-medium" style={{ color: "var(--text)" }}>{label}</span>
        {help && <p className="text-xs" style={{ color: "var(--text-dim)" }}>{help}</p>}
      </div>
      <button type="button" role="switch" aria-checked={checked} aria-label={label}
        onClick={() => onChange(!checked)}
        className="relative h-6 w-11 shrink-0 rounded-full transition-colors focus-visible:outline-2"
        style={{ background: checked ? "var(--primary)" : "var(--surface-muted)", border: "1px solid var(--border)" }}>
        <span className="absolute top-0.5 h-4 w-4 rounded-full transition-all"
          style={{ left: checked ? "1.5rem" : "0.15rem", background: checked ? "#08120b" : "var(--text-muted)" }} />
      </button>
    </div>
  );
}
```

Create `src/components/controls/Slider.tsx`:

```tsx
"use client";
import { clampSlider } from "@/lib/form/control-value";

export function Slider({ value, min, max, step, onChange, label, unit }: {
  value: number;
  min?: number;
  max?: number;
  step?: number;
  onChange: (v: number) => void;
  label: string;
  unit?: string;
}) {
  return (
    <div className="py-1.5">
      <div className="flex items-baseline justify-between">
        <label className="text-sm font-medium" style={{ color: "var(--text)" }}>{label}</label>
        <span className="text-sm tabular-nums" style={{ color: "var(--text-muted)" }}>
          {value}{unit ? ` ${unit}` : ""}
        </span>
      </div>
      <input type="range" value={value}
        min={min ?? 0} max={max ?? 100} step={step ?? 1}
        onChange={(e) => onChange(clampSlider(Number(e.target.value), min, max))}
        className="mt-1 w-full accent-[var(--primary)]" style={{ accentColor: "var(--primary)" }} />
    </div>
  );
}
```

Create `src/components/controls/CardSelect.tsx`:

```tsx
"use client";
import { coerceOptionValue } from "@/lib/form/control-value";
import type { FormValue } from "@/lib/form/types";

export function CardSelect({ options, value, onChange, label }: {
  options: { value: string | number; label: string }[];
  value: FormValue;
  onChange: (v: FormValue) => void;
  label: string;
}) {
  return (
    <div className="py-1">
      <span className="block text-sm font-medium mb-1.5" style={{ color: "var(--text)" }}>{label}</span>
      <div className="grid grid-cols-2 gap-2">
        {options.map((o) => {
          const selected = String(o.value) === String(value);
          return (
            <button key={String(o.value)} type="button" aria-pressed={selected}
              onClick={() => onChange(coerceOptionValue(options, String(o.value)))}
              className="rounded-lg px-3 py-2.5 text-sm text-left transition-colors focus-visible:outline-2"
              style={{
                background: selected ? "var(--surface-muted)" : "var(--surface)",
                border: `1px solid ${selected ? "var(--primary)" : "var(--border)"}`,
                color: selected ? "var(--text)" : "var(--text-muted)",
              }}>
              {o.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
```

- [ ] **Step 6: Dispatch from Field**

Replace `src/components/controls/Field.tsx`'s control switch so it routes the new kinds (keep the existing select/number/text/toggle for fallback). The new file:

```tsx
"use client";
import type { ResolvedField, FormValue } from "@/lib/form/types";
import { Segmented } from "./Segmented";
import { Switch } from "./Switch";
import { Slider } from "./Slider";
import { CardSelect } from "./CardSelect";
import { coerceOptionValue } from "@/lib/form/control-value";

export function Field({ field, value, onChange }: {
  field: ResolvedField;
  value: FormValue;
  onChange: (v: FormValue) => void;
}) {
  switch (field.control) {
    case "segmented":
      return <Segmented options={field.options ?? []} value={value} onChange={onChange} label={field.label} />;
    case "cards":
      return <CardSelect options={field.options ?? []} value={value} onChange={onChange} label={field.label} />;
    case "switch":
    case "toggle":
      return <Switch checked={value === true} onChange={onChange} label={field.label} help={field.help} />;
    case "slider":
      return <Slider value={Number(value)} min={field.min} max={field.max} step={field.step}
        onChange={onChange} label={field.label} unit={undefined} />;
    case "select":
      return (
        <div className="py-1">
          <label className="block text-sm font-medium" style={{ color: "var(--text)" }}>{field.label}</label>
          <select value={String(value)} onChange={(e) => onChange(coerceOptionValue(field.options, e.target.value))}
            className="mt-1 w-full rounded px-2 py-1.5 text-sm"
            style={{ background: "var(--surface-muted)", color: "var(--text)", border: "1px solid var(--border)" }}>
            {field.options?.map((o) => <option key={String(o.value)} value={String(o.value)}>{o.label}</option>)}
          </select>
        </div>
      );
    case "number":
      return (
        <div className="py-1">
          <label className="block text-sm font-medium" style={{ color: "var(--text)" }}>{field.label}</label>
          <input type="number" value={Number(value)} min={field.min} max={field.max} step={field.step ?? "any"}
            onChange={(e) => onChange(e.target.value === "" ? 0 : Number(e.target.value))}
            className="mt-1 w-full rounded px-2 py-1.5 text-sm"
            style={{ background: "var(--surface-muted)", color: "var(--text)", border: "1px solid var(--border)" }} />
        </div>
      );
    default:
      return (
        <div className="py-1">
          <label className="block text-sm font-medium" style={{ color: "var(--text)" }}>{field.label}</label>
          <input type="text" value={String(value)} onChange={(e) => onChange(e.target.value)}
            className="mt-1 w-full rounded px-2 py-1.5 text-sm"
            style={{ background: "var(--surface-muted)", color: "var(--text)", border: "1px solid var(--border)" }} />
        </div>
      );
  }
}
```

- [ ] **Step 7: Suite + build**

Run: `npm run test` (control-value + all prior green).
Run: `npx tsc --noEmit` (clean) and `npm run build` (compiles).

- [ ] **Step 8: Commit**

```bash
git add src/lib/form/types.ts src/lib/form/control-value.ts src/lib/form/control-value.test.ts src/components/controls
git commit -m "feat(ui): control-kit primitives (segmented, switch, slider, cards) + Field dispatch"
```

---

### Task 2: Film-format picker (the signature)

The distinctive control: aspect-ratio chips + a "filed edges" toggle + a Custom option. The format↔(base,filed) mapping is pure logic (TDD'd), and a test guards that every producible value exists in the real schema enum.

**Files:**
- Create: `src/lib/film-format.ts` (chips data + value mapping)
- Test: `src/lib/film-format.test.ts`
- Create: `src/components/controls/FilmFormatPicker.tsx`

**Interfaces:**
- Produces:
  - `interface FormatChip { base: string; label: string; ratio: [number, number]; hasFiled: boolean }`
  - `const FORMAT_CHIPS: FormatChip[]`
  - `function toFilmFormatValue(base: string, filed: boolean): string`
  - `function fromFilmFormatValue(value: string): { base: string; filed: boolean }`
  - `function FilmFormatPicker(props: { value: string; onChange: (v: string) => void })`

- [ ] **Step 1: Write the failing tests (incl. the schema-enum guard)**

Create `src/lib/film-format.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { FORMAT_CHIPS, toFilmFormatValue, fromFilmFormatValue } from "./film-format";
import schema from "../../generated/param-schema.json";
import type { ParamSchema } from "./params/types";

describe("film-format mapping", () => {
  it("round-trips base + filed through value", () => {
    expect(toFilmFormatValue("6x6", false)).toBe("6x6");
    expect(toFilmFormatValue("6x6", true)).toBe("6x6 filed");
    expect(fromFilmFormatValue("6x6 filed")).toEqual({ base: "6x6", filed: true });
    expect(fromFilmFormatValue("6x6")).toEqual({ base: "6x6", filed: false });
  });

  it("never marks a non-filed base as filed", () => {
    // 4x5 has no filed variant in the schema
    expect(toFilmFormatValue("4x5", true)).toBe("4x5");
  });

  it("every producible value exists in the schema's Film_Format enum", () => {
    const s = schema as ParamSchema;
    const filmFormat = s.params.find((p) => p.name === "Film_Format");
    const allowed = new Set((filmFormat?.options ?? []).map((o) => String(o.value)));
    for (const chip of FORMAT_CHIPS) {
      expect(allowed.has(toFilmFormatValue(chip.base, false))).toBe(true);
      if (chip.hasFiled) expect(allowed.has(toFilmFormatValue(chip.base, true))).toBe(true);
    }
  });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `npm run test -- film-format`
Expected: FAIL — not defined.

- [ ] **Step 3: Implement the mapping + chips**

Create `src/lib/film-format.ts`. The chip set + `hasFiled` flags are derived from the schema's actual enum (base formats that have an `"X filed"` sibling). Ratios are presentation data (true frame proportions):

```ts
export interface FormatChip {
  base: string;
  label: string;
  ratio: [number, number];
  hasFiled: boolean;
}

// Base formats shown as chips (the schema's "X filed" variants collapse into the
// `filed` toggle; "custom" is handled separately by the picker).
export const FORMAT_CHIPS: FormatChip[] = [
  { base: "35mm", label: "35mm", ratio: [3, 2], hasFiled: true },
  { base: "35mm full", label: "35mm full", ratio: [3, 2], hasFiled: false },
  { base: "half frame", label: "Half", ratio: [4, 3], hasFiled: false },
  { base: "6x4.5", label: "6×4.5", ratio: [4, 3], hasFiled: true },
  { base: "6x6", label: "6×6", ratio: [1, 1], hasFiled: true },
  { base: "6x7", label: "6×7", ratio: [5, 4], hasFiled: true },
  { base: "6x8", label: "6×8", ratio: [7, 5], hasFiled: true },
  { base: "6x9", label: "6×9", ratio: [3, 2], hasFiled: true },
  { base: "4x5", label: "4×5", ratio: [5, 4], hasFiled: false },
];

const FILED_SUFFIX = " filed";

export function toFilmFormatValue(base: string, filed: boolean): string {
  const chip = FORMAT_CHIPS.find((c) => c.base === base);
  return filed && chip?.hasFiled ? `${base}${FILED_SUFFIX}` : base;
}

export function fromFilmFormatValue(value: string): { base: string; filed: boolean } {
  if (value.endsWith(FILED_SUFFIX)) {
    return { base: value.slice(0, -FILED_SUFFIX.length), filed: true };
  }
  return { base: value, filed: false };
}
```

- [ ] **Step 4: Run to verify pass**

Run: `npm run test -- film-format`
Expected: PASS (3 tests; the schema-enum guard confirms chips match the real enum).

- [ ] **Step 5: Build the picker**

Create `src/components/controls/FilmFormatPicker.tsx`. Each chip draws a frame at its true aspect ratio (max 44px on the long edge). A "filed edges" switch shows only when the selected base has a filed variant. A "Custom" chip selects `Film_Format="custom"` (the page reveals the dimension sliders via existing conditional visibility).

```tsx
"use client";
import { FORMAT_CHIPS, fromFilmFormatValue, toFilmFormatValue } from "@/lib/film-format";
import { Switch } from "./Switch";

const MAX = 44; // px, long edge of the frame glyph

function frameSize([w, h]: [number, number]): { width: number; height: number } {
  const scale = MAX / Math.max(w, h);
  return { width: Math.round(w * scale), height: Math.round(h * scale) };
}

export function FilmFormatPicker({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  const isCustom = value === "custom";
  const { base, filed } = isCustom ? { base: "", filed: false } : fromFilmFormatValue(value);
  const activeChip = FORMAT_CHIPS.find((c) => c.base === base);

  return (
    <div className="py-1">
      <span className="block text-sm font-medium mb-2" style={{ color: "var(--text)" }}>Film format</span>
      <div className="flex flex-wrap gap-2">
        {FORMAT_CHIPS.map((chip) => {
          const selected = !isCustom && chip.base === base;
          const { width, height } = frameSize(chip.ratio);
          return (
            <button key={chip.base} type="button" aria-pressed={selected}
              onClick={() => onChange(toFilmFormatValue(chip.base, filed))}
              className="flex flex-col items-center justify-end gap-1 rounded-lg px-3 py-2 transition-colors focus-visible:outline-2"
              style={{ width: 76, height: 76,
                background: selected ? "var(--surface-muted)" : "var(--surface)",
                border: `1px solid ${selected ? "var(--primary)" : "var(--border)"}` }}>
              <span className="flex flex-1 items-center justify-center">
                <span style={{ width, height, border: `2px solid ${selected ? "var(--primary)" : "var(--text-dim)"}`, borderRadius: 2 }} />
              </span>
              <span className="text-xs" style={{ color: selected ? "var(--text)" : "var(--text-muted)" }}>{chip.label}</span>
            </button>
          );
        })}
        <button type="button" aria-pressed={isCustom} onClick={() => onChange("custom")}
          className="flex flex-col items-center justify-center gap-1 rounded-lg px-3 py-2 transition-colors focus-visible:outline-2"
          style={{ width: 76, height: 76,
            background: isCustom ? "var(--surface-muted)" : "var(--surface)",
            border: `1px solid ${isCustom ? "var(--primary)" : "var(--border)"}`,
            color: isCustom ? "var(--text)" : "var(--text-muted)" }}>
          <span className="text-lg leading-none">＋</span>
          <span className="text-xs">Custom</span>
        </button>
      </div>

      {activeChip?.hasFiled && (
        <div className="mt-2">
          <Switch checked={filed} onChange={(f) => onChange(toFilmFormatValue(base, f))}
            label="Filed edges" help="Wider opening that shows the filed negative edge." />
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 6: Suite + build**

Run: `npm run test` (film-format + prior green). `npx tsc --noEmit` clean. `npm run build` compiles.

- [ ] **Step 7: Commit**

```bash
git add src/lib/film-format.ts src/lib/film-format.test.ts src/components/controls/FilmFormatPicker.tsx
git commit -m "feat(ui): film-format picker with true-aspect-ratio chips + filed/custom"
```

---

### Task 3: Carrier outline SVGs + enlarger card silhouettes

Each enlarger card shows an SVG silhouette of that carrier's general outline (outer body only — no film opening). Outlines are generated once from the real geometry and committed; the cards consume them via a small `optionVisual` extension to the control model. `Carrier_Type` stays a `cards` field in the overlay (no bespoke picker needed).

**Files:**
- Modify: `src/lib/form/types.ts` (add `optionVisual?` to `FieldConfig` + `ResolvedField`)
- Modify: `src/lib/form/form-model.ts` (pass `optionVisual` through `resolveFormModel`)
- Create: `src/lib/outline/outer-contour.ts` (extract the outer contour from an OpenSCAD-exported SVG)
- Test: `src/lib/outline/outer-contour.test.ts`
- Create: `scripts/gen-carrier-outlines.ts` (generate once: WASM `projection()` → SVG → outer contour → file)
- Create (generated, committed): `public/outlines/<carrier_type>.svg` per carrier type
- Create: `src/lib/outline/outlines.ts` (`CARRIER_OUTLINES`: carrier value → SVG url)
- Modify: `src/components/controls/CardSelect.tsx` (render an optional per-option visual)
- Modify: `src/components/controls/Field.tsx` (pass the outline visual for `optionVisual==="carrier-outline"`)

**Interfaces:**
- Produces:
  - `FieldConfig.optionVisual?: "carrier-outline"` and `ResolvedField.optionVisual?: "carrier-outline"`
  - `function extractOuterContour(svg: string): { d: string; viewBox: string }` — from an SVG with one or more subpaths, return only the largest (outer) contour's path `d` and a tight `viewBox` (drops inner "hole" contours).
  - `const CARRIER_OUTLINES: Record<string, string>` — carrier value → public SVG url (e.g. `/outlines/omega-d.svg`).
  - `CardSelect` gains an optional `renderVisual?: (value: string | number) => React.ReactNode`.

- [ ] **Step 1: Add `optionVisual` to the types and resolver (pass-through)**

In `src/lib/form/types.ts`, add `optionVisual?: "carrier-outline";` to BOTH `FieldConfig` and `ResolvedField`.
In `src/lib/form/form-model.ts`, in the object `resolveFormModel` builds for each field, add `optionVisual: fc.optionVisual,`. (No behavior change for fields without it.)

- [ ] **Step 2: Write the failing test for outer-contour extraction**

Create `src/lib/outline/outer-contour.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { extractOuterContour } from "./outer-contour";

// An OpenSCAD-style SVG: a big outer square (0,0..100,100) and a small inner
// square (40,40..60,60) — the inner one is a "hole" and must be dropped.
const svg = `<svg xmlns="http://www.w3.org/2000/svg"><path d="M0,0 L100,0 L100,100 L0,100 Z M40,40 L60,40 L60,60 L40,60 Z" /></svg>`;

describe("extractOuterContour", () => {
  it("keeps only the largest (outer) subpath", () => {
    const { d } = extractOuterContour(svg);
    expect(d).toContain("M0,0");
    expect(d).not.toContain("M40,40"); // inner hole dropped
  });
  it("returns a viewBox covering the outer contour", () => {
    const { viewBox } = extractOuterContour(svg);
    expect(viewBox).toBe("0 0 100 100");
  });
  it("throws when no path data is present", () => {
    expect(() => extractOuterContour("<svg></svg>")).toThrow();
  });
});
```

- [ ] **Step 3: Run to verify failure**

Run: `npm run test -- outer-contour`
Expected: FAIL — not defined.

- [ ] **Step 4: Implement outer-contour extraction**

Create `src/lib/outline/outer-contour.ts`. Split the path `d` into subpaths (each starts with `M`/`m`), parse the numeric coordinates of each, pick the subpath with the largest bounding-box area, and compute a tight integer `viewBox`:

```ts
function subpaths(d: string): string[] {
  // Split before each moveto command, keep the command.
  return d.split(/(?=[Mm])/).map((s) => s.trim()).filter(Boolean);
}

function coords(sub: string): { xs: number[]; ys: number[] } {
  const nums = (sub.match(/-?\d*\.?\d+(?:e-?\d+)?/gi) ?? []).map(Number);
  const xs: number[] = [], ys: number[] = [];
  for (let i = 0; i + 1 < nums.length; i += 2) { xs.push(nums[i]); ys.push(nums[i + 1]); }
  return { xs, ys };
}

function bboxArea(sub: string): number {
  const { xs, ys } = coords(sub);
  if (xs.length === 0) return 0;
  return (Math.max(...xs) - Math.min(...xs)) * (Math.max(...ys) - Math.min(...ys));
}

export function extractOuterContour(svg: string): { d: string; viewBox: string } {
  const dMatch = svg.match(/\bd\s*=\s*"([^"]+)"/);
  if (!dMatch) throw new Error("no path data found in SVG");
  const subs = subpaths(dMatch[1]);
  if (subs.length === 0) throw new Error("no subpaths in path data");
  const outer = subs.reduce((a, b) => (bboxArea(b) >= bboxArea(a) ? b : a));
  const { xs, ys } = coords(outer);
  const minX = Math.floor(Math.min(...xs)), minY = Math.floor(Math.min(...ys));
  const w = Math.ceil(Math.max(...xs)) - minX, h = Math.ceil(Math.max(...ys)) - minY;
  return { d: outer, viewBox: `${minX} ${minY} ${w} ${h}` };
}
```

- [ ] **Step 5: Run to verify pass**

Run: `npm run test -- outer-contour`
Expected: PASS (3 tests).

- [ ] **Step 6: Generate the carrier outline SVGs (the discovery step)**

Create `scripts/gen-carrier-outlines.ts`. For each carrier type, render the carrier's **body outline** to SVG via the vendored WASM engine and OpenSCAD `projection()`, run `extractOuterContour`, and write `public/outlines/<value>.svg`.

**Approach (investigate, then pick):** `carrier.scad` runs its assembly at the top level, so you cannot wrap it in `projection()` directly. Inspect `public/scad/src/<carrier>-base-shape.scad` to find the base-shape module(s) that produce the carrier body, and write a tiny wrapper `.scad` into the WASM FS that `include`s the synced `src` and renders `projection() <base_shape>(...)` (body only — no film opening, no text, no pegs, no alignment board). Run it with the engine using SVG export args (`-o out.svg --export-format=svg --enable=all`) — note: the render core hardcodes `binstl`, so call the engine factory directly (as `render.integration.test.ts` does) rather than through `renderScad`. Then feed the SVG through `extractOuterContour` and write the file.

```ts
// scripts/gen-carrier-outlines.ts (shape — fill in the wrapper SCAD after investigating base-shape modules)
import { readFileSync, readdirSync, writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { extractOuterContour } from "../src/lib/outline/outer-contour";

const CARRIERS = ["omega-d", "lpl-saunders-45xx", "beseler-23c", "beseler-45", "frameAndPegTest"];

async function main() {
  mkdirSync(join(process.cwd(), "public/outlines"), { recursive: true });
  const wasmBinary = new Uint8Array(readFileSync("public/wasm/openscad.wasm"));
  const factory = (await import(join(process.cwd(), "public/wasm/openscad.js"))).default as (o: object) => Promise<any>;
  // ... mount the synced /scad tree + /BOSL2 (same rooting as render.ts) ...
  for (const carrier of CARRIERS) {
    const inst = await factory({ noInitialRun: true, wasmBinary });
    // ... write all FS assets, plus an /outline.scad wrapper that projects this carrier's base shape ...
    inst.callMain(["/outline.scad", "-o", "/o.svg", "--export-format=svg", "--enable=all"]);
    const svg = new TextDecoder().decode(inst.FS.readFile("/o.svg"));
    const { d, viewBox } = extractOuterContour(svg);
    writeFileSync(`public/outlines/${carrier}.svg`,
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}"><path d="${d}" fill="currentColor"/></svg>`);
    console.log(`wrote public/outlines/${carrier}.svg`);
  }
}
main();
```

Add an npm script `"gen:outlines": "tsx scripts/gen-carrier-outlines.ts"` and run it.

**FALLBACK (if the projection route is intractable** — base-shape modules not cleanly callable standalone, or the opening can't be excluded from the projection): hand-author a simplified silhouette `<svg>` per carrier (the spec calls for the "general shape", so an approximation is acceptable) and commit them to `public/outlines/`. **In your report, state clearly which path you took** (generated-from-geometry vs hand-authored) and why.

Either way, verify each `public/outlines/<value>.svg` exists, is a single outer path, and renders as a recognizable carrier silhouette (open one in a browser).

- [ ] **Step 7: Outline map + CardSelect visual**

Create `src/lib/outline/outlines.ts`:

```ts
export const CARRIER_OUTLINES: Record<string, string> = {
  "omega-d": "/outlines/omega-d.svg",
  "lpl-saunders-45xx": "/outlines/lpl-saunders-45xx.svg",
  "beseler-23c": "/outlines/beseler-23c.svg",
  "beseler-45": "/outlines/beseler-45.svg",
  "frameAndPegTest": "/outlines/frameAndPegTest.svg",
};
```

In `src/components/controls/CardSelect.tsx`, accept an optional `renderVisual` and show it above the label:

```tsx
// add to props: renderVisual?: (value: string | number) => React.ReactNode
// inside each card button, above the label:
{renderVisual && <span className="mb-1.5 flex h-10 items-center justify-center" aria-hidden>{renderVisual(o.value)}</span>}
```

In `src/components/controls/Field.tsx`, for the `"cards"` case, pass a `renderVisual` when `field.optionVisual === "carrier-outline"` that renders an `<img>` of the carrier outline (tinted via CSS `currentColor`/filter or just shown at low opacity):

```tsx
case "cards":
  return <CardSelect options={field.options ?? []} value={value} onChange={onChange} label={field.label}
    renderVisual={field.optionVisual === "carrier-outline"
      ? (v) => {
          const src = CARRIER_OUTLINES[String(v)];
          return src ? <img src={src} alt="" aria-hidden className="h-9 w-auto opacity-80" /> : null;
        }
      : undefined} />;
```

(Import `CARRIER_OUTLINES` in `Field.tsx`. The SVG is decorative — `aria-hidden` + empty `alt`; the card's text label is the accessible name.)

- [ ] **Step 8: Suite + build**

Run: `npm run test` (outer-contour + all prior green). `npx tsc --noEmit` clean. `npm run build` compiles (the `/outlines/*.svg` are static public assets).

- [ ] **Step 9: Commit**

```bash
git add src/lib/form/types.ts src/lib/form/form-model.ts src/lib/outline scripts/gen-carrier-outlines.ts public/outlines src/components/controls/CardSelect.tsx src/components/controls/Field.tsx package.json
git commit -m "feat(ui): enlarger cards show generated carrier-outline silhouettes"
```

---

### Task 4: Rewrite the curation overlay to use friendly controls

Assign each field a friendly control kind; the consistency test still guards against schema drift. `Film_Format` is removed from the generic overlay (the page mounts the bespoke `FilmFormatPicker` for it).

**Files:**
- Modify: `src/config/carrier-ui.ts`
- Modify: `src/config/carrier-ui.test.ts` (still passes; add an assertion that control kinds resolve)

**Interfaces:**
- Consumes: `GroupConfig`/`FieldConfig` (control kinds from the extended `ControlKind`).
- Produces: the updated `CARRIER_UI` (no `Film_Format` field — handled by the picker).

- [ ] **Step 1: Rewrite the overlay**

Replace `src/config/carrier-ui.ts`. Each field declares its friendly control; `Film_Format` is intentionally omitted (mounted separately). Conditional visibility predicates are preserved from Plan 2:

```ts
import type { GroupConfig, FormValue } from "../lib/form/types";

const isCustomFormat = (v: Record<string, FormValue>) => v.Film_Format === "custom";

export const CARRIER_UI: GroupConfig[] = [
  {
    title: "Carrier",
    fields: [
      { param: "Carrier_Type", label: "Enlarger", control: "cards", optionVisual: "carrier-outline", help: "Which enlarger this carrier fits." },
      { param: "Orientation", label: "Orientation", control: "segmented", help: "Ignored for 4×5." },
      { param: "Top_or_Bottom", label: "Part", control: "segmented", help: "A full carrier needs both top and bottom printed." },
    ],
  },
  {
    title: "Custom size",
    fields: [
      { param: "Custom_Film_Width", label: "Film width", control: "slider", visibleWhen: isCustomFormat },
      { param: "Custom_Film_Height", label: "Film height", control: "slider", visibleWhen: isCustomFormat },
      { param: "Custom_Opening_Width", label: "Opening width", control: "slider", visibleWhen: isCustomFormat },
      { param: "Custom_Opening_Height", label: "Opening height", control: "slider", visibleWhen: isCustomFormat },
    ],
  },
  {
    title: "Text",
    fields: [
      { param: "Enable_Owner_Name_Etch", label: "Etch a name", control: "switch" },
      { param: "Owner_Name", label: "Name", control: "text", visibleWhen: (v) => v.Enable_Owner_Name_Etch === true },
      { param: "Enable_Type_Name_Etch", label: "Etch the carrier type", control: "switch" },
      { param: "Type_Name", label: "Type label", control: "segmented", visibleWhen: (v) => v.Enable_Type_Name_Etch === true },
      { param: "Custom_Type_Name", label: "Custom label", control: "text",
        visibleWhen: (v) => v.Enable_Type_Name_Etch === true && v.Type_Name === "Custom" },
      { param: "Fontface", label: "Font", control: "segmented", optionsFrom: "fonts" },
      { param: "Font_Size", label: "Font size", control: "slider" },
    ],
  },
  {
    title: "Options",
    fields: [
      { param: "Alignment_Board", label: "Include alignment board", control: "switch" },
      { param: "Alignment_Board_Type", label: "Board type", control: "segmented",
        visibleWhen: (v) => v.Alignment_Board === true },
      { param: "Printed_or_Heat_Set_Pegs", label: "Pegs", control: "segmented",
        help: "Heat-set required when including the alignment board." },
      { param: "Flip_Bottom_For_Printing", label: "Flip bottom for printing", control: "switch" },
    ],
  },
  {
    title: "Advanced",
    fields: [
      { param: "TEXT_ETCH_DEPTH", label: "Etch depth", control: "slider", advanced: true },
      { param: "Owner_Text_X_Offset", label: "Name X offset", control: "slider", advanced: true },
      { param: "Owner_Text_Y_Offset", label: "Name Y offset", control: "slider", advanced: true },
      { param: "Type_Text_X_Offset", label: "Type X offset", control: "slider", advanced: true },
      { param: "Type_Text_Y_Offset", label: "Type Y offset", control: "slider", advanced: true },
      { param: "Peg_Gap", label: "Peg gap", control: "slider", advanced: true },
      { param: "Adjust_Film_Width", label: "Adjust film width", control: "slider", advanced: true },
      { param: "Adjust_Film_Height", label: "Adjust film height", control: "slider", advanced: true },
      { param: "Text_As_Separate_Parts", label: "Separate text parts (multi-material)", control: "switch", advanced: true },
      { param: "Layer_Height_mm", label: "Layer height", control: "slider", advanced: true,
        visibleWhen: (v) => v.Text_As_Separate_Parts === true },
      { param: "Text_Layer_Multiple", label: "Text layers", control: "slider", advanced: true,
        visibleWhen: (v) => v.Text_As_Separate_Parts === true },
    ],
  },
];
```

> **Note on slider bounds:** sliders need `min`/`max` from the schema. Params with a `// [min:max]` annotation already carry them. For params declared as bare numbers (e.g. offsets, `Custom_*`), the resolved `min`/`max` are `undefined` and `Slider` defaults to `0..100` (Task 1). If a sensible range matters for a specific param, widen the schema annotation in DarkroomSCAD `carrier.scad` (out of scope here) or accept the 0..100 default. Offsets that need negatives will be clamped at 0 by the default min — **flag any such param in your report**; the controller will decide whether to special-case it (e.g. keep those as `number` control) rather than silently lose negative offsets.

- [ ] **Step 2: Strengthen the consistency test**

Update `src/config/carrier-ui.test.ts` to also assert resolution yields the expected control kinds for a couple of representative fields:

```ts
import { describe, it, expect } from "vitest";
import { CARRIER_UI } from "./carrier-ui";
import { validateOverlay, resolveFormModel } from "../lib/form/form-model";
import schema from "../../generated/param-schema.json";
import type { ParamSchema } from "../lib/params/types";

describe("carrier-ui overlay vs generated schema", () => {
  const s = schema as ParamSchema;
  it("references only params that exist in the generated schema", () => {
    expect(validateOverlay(s, CARRIER_UI)).toEqual([]);
  });
  it("resolves and assigns the intended control kinds", () => {
    const groups = resolveFormModel(s, CARRIER_UI);
    const byParam = Object.fromEntries(groups.flatMap((g) => g.fields).map((f) => [f.param, f]));
    expect(byParam.Carrier_Type.control).toBe("cards");
    expect(byParam.Orientation.control).toBe("segmented");
    expect(byParam.Enable_Owner_Name_Etch.control).toBe("switch");
    expect(byParam.Font_Size.control).toBe("slider");
  });
  it("does not include Film_Format (handled by the bespoke picker)", () => {
    const params = CARRIER_UI.flatMap((g) => g.fields).map((f) => f.param);
    expect(params).not.toContain("Film_Format");
  });
});
```

- [ ] **Step 3: Suite + build**

Run: `npm run test -- carrier-ui` (green). `npx tsc --noEmit` clean. `npm run build` compiles.

- [ ] **Step 4: Commit**

```bash
git add src/config/carrier-ui.ts src/config/carrier-ui.test.ts
git commit -m "feat(ui): map carrier params to friendly controls; Film_Format -> bespoke picker"
```

---

### Task 5: Theme system (dark / light / darkroom-safelight / high-contrast)

Tokens as TS objects (single source of truth) applied as CSS vars, a provider with persistence + `prefers-color-scheme`, a toggle, and viewer colors exposed to the 3D viewer (addresses the unused `--viewer-*` tokens).

**Files:**
- Create: `src/lib/theme/themes.ts` (the four token sets + types)
- Create: `src/lib/theme/resolve.ts` (initial-theme + cycle logic)
- Test: `src/lib/theme/resolve.test.ts`
- Create: `src/components/ThemeProvider.tsx` (context: applies CSS vars, persists, exposes viewer colors)
- Create: `src/components/ThemeToggle.tsx`
- Modify: `src/app/layout.tsx` (wrap in ThemeProvider; add a no-flash inline script)
- Modify: `src/components/StlViewer.tsx` (read viewer colors from theme context)

**Interfaces:**
- Produces:
  - `type ThemeName = "dark" | "light" | "darkroom" | "high-contrast"`
  - `interface ThemeTokens { vars: Record<string, string>; viewer: { model: string; grid: string; background: string } }`
  - `const THEMES: Record<ThemeName, ThemeTokens>`
  - `function resolveInitialTheme(stored: string | null, prefersDark: boolean): ThemeName`
  - `function nextTheme(current: ThemeName): ThemeName`
  - `useTheme(): { theme: ThemeName; setTheme(t): void; viewer: ThemeTokens["viewer"] }`

- [ ] **Step 1: Write the failing tests for resolve logic**

Create `src/lib/theme/resolve.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { resolveInitialTheme, nextTheme } from "./resolve";

describe("resolveInitialTheme", () => {
  it("uses the stored theme when valid", () => {
    expect(resolveInitialTheme("light", true)).toBe("light");
    expect(resolveInitialTheme("darkroom", false)).toBe("darkroom");
  });
  it("falls back to prefers-color-scheme when unset/invalid", () => {
    expect(resolveInitialTheme(null, true)).toBe("dark");
    expect(resolveInitialTheme(null, false)).toBe("light");
    expect(resolveInitialTheme("bogus", false)).toBe("light");
  });
});

describe("nextTheme", () => {
  it("cycles dark -> light -> darkroom -> high-contrast -> dark", () => {
    expect(nextTheme("dark")).toBe("light");
    expect(nextTheme("light")).toBe("darkroom");
    expect(nextTheme("darkroom")).toBe("high-contrast");
    expect(nextTheme("high-contrast")).toBe("dark");
  });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `npm run test -- theme/resolve`
Expected: FAIL — not defined.

- [ ] **Step 3: Implement themes + resolve**

Create `src/lib/theme/themes.ts`. The `vars` keys mirror the CSS custom properties from Plan 2's `theme.css`; `dark` values match what shipped. `darkroom` is the red-on-black safelight set; `high-contrast` is pure black/white with a single bright accent.

```ts
export type ThemeName = "dark" | "light" | "darkroom" | "high-contrast";

export interface ThemeTokens {
  vars: Record<string, string>;
  viewer: { model: string; grid: string; background: string };
}

export const THEMES: Record<ThemeName, ThemeTokens> = {
  dark: {
    vars: {
      "--bg": "#09090b", "--surface": "#121214", "--surface-muted": "#1c1c1f",
      "--border": "rgba(255,255,255,0.1)", "--border-strong": "rgba(255,255,255,0.2)",
      "--text": "#ffffff", "--text-muted": "#a1a1aa", "--text-dim": "#71717a",
      "--primary": "#6ef3a4", "--secondary": "#7dd6ff", "--accent": "#f99f96",
      "--highlight": "#e5ff7d", "--error": "#f99f96", "--success": "#6ef3a4",
      "--viewer-model": "#9a9a9a", "--viewer-grid": "#353535",
    },
    viewer: { model: "#9a9a9a", grid: "#353535", background: "#121214" },
  },
  light: {
    vars: {
      "--bg": "#ffffff", "--surface": "#f8f9fa", "--surface-muted": "#f1f3f4",
      "--border": "rgba(0,0,0,0.12)", "--border-strong": "rgba(0,0,0,0.24)",
      "--text": "#09090b", "--text-muted": "#52525b", "--text-dim": "#71717a",
      "--primary": "#2d7a4a", "--secondary": "#1e6091", "--accent": "#c4524a",
      "--highlight": "#8b9c2e", "--error": "#c4524a", "--success": "#2d7a4a",
      "--viewer-model": "#b8b8b8", "--viewer-grid": "#d4d4d8",
    },
    viewer: { model: "#b8b8b8", grid: "#d4d4d8", background: "#f8f9fa" },
  },
  darkroom: {
    vars: {
      "--bg": "#000000", "--surface": "#0a0000", "--surface-muted": "#140000",
      "--border": "#5a0000", "--border-strong": "#7a0000",
      "--text": "#ff2a2a", "--text-muted": "#a90000", "--text-dim": "#7a0000",
      "--primary": "#ff2a2a", "--secondary": "#ff2a2a", "--accent": "#ff2a2a",
      "--highlight": "#ff2a2a", "--error": "#ff6a6a", "--success": "#ff2a2a",
      "--viewer-model": "#8a0000", "--viewer-grid": "#3a0000",
    },
    viewer: { model: "#8a0000", grid: "#3a0000", background: "#0a0000" },
  },
  "high-contrast": {
    vars: {
      "--bg": "#000000", "--surface": "#000000", "--surface-muted": "#111111",
      "--border": "#ffffff", "--border-strong": "#ffffff",
      "--text": "#ffffff", "--text-muted": "#e4e4e7", "--text-dim": "#a1a1aa",
      "--primary": "#ffff00", "--secondary": "#00ffff", "--accent": "#ffff00",
      "--highlight": "#ffff00", "--error": "#ff6a6a", "--success": "#00ff00",
      "--viewer-model": "#d4d4d4", "--viewer-grid": "#666666",
    },
    viewer: { model: "#d4d4d4", grid: "#666666", background: "#000000" },
  },
};
```

Create `src/lib/theme/resolve.ts`:

```ts
import type { ThemeName } from "./themes";

const ORDER: ThemeName[] = ["dark", "light", "darkroom", "high-contrast"];
const VALID = new Set<ThemeName>(ORDER);

export function resolveInitialTheme(stored: string | null, prefersDark: boolean): ThemeName {
  if (stored && VALID.has(stored as ThemeName)) return stored as ThemeName;
  return prefersDark ? "dark" : "light";
}

export function nextTheme(current: ThemeName): ThemeName {
  const i = ORDER.indexOf(current);
  return ORDER[(i + 1) % ORDER.length];
}
```

- [ ] **Step 4: Run to verify pass**

Run: `npm run test -- theme/resolve`
Expected: PASS.

- [ ] **Step 5: Provider + toggle**

Create `src/components/ThemeProvider.tsx`:

```tsx
"use client";
import { createContext, useContext, useEffect, useState } from "react";
import { THEMES, type ThemeName, type ThemeTokens } from "@/lib/theme/themes";
import { resolveInitialTheme } from "@/lib/theme/resolve";

const STORAGE_KEY = "darkroomscad-theme";

const ThemeContext = createContext<{
  theme: ThemeName;
  setTheme: (t: ThemeName) => void;
  viewer: ThemeTokens["viewer"];
}>({ theme: "dark", setTheme: () => {}, viewer: THEMES.dark.viewer });

function applyVars(theme: ThemeName) {
  const root = document.documentElement;
  for (const [k, v] of Object.entries(THEMES[theme].vars)) root.style.setProperty(k, v);
  root.setAttribute("data-theme", theme);
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<ThemeName>("dark");
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const initial = resolveInitialTheme(stored, prefersDark);
    setThemeState(initial);
    applyVars(initial);
  }, []);
  const setTheme = (t: ThemeName) => {
    setThemeState(t);
    applyVars(t);
    localStorage.setItem(STORAGE_KEY, t);
  };
  return (
    <ThemeContext.Provider value={{ theme, setTheme, viewer: THEMES[theme].viewer }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);
```

Create `src/components/ThemeToggle.tsx`:

```tsx
"use client";
import { useTheme } from "./ThemeProvider";
import { nextTheme } from "@/lib/theme/resolve";

const LABEL: Record<string, string> = {
  dark: "Dark", light: "Light", darkroom: "Safelight", "high-contrast": "High contrast",
};

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  return (
    <button type="button" onClick={() => setTheme(nextTheme(theme))}
      aria-label={`Theme: ${LABEL[theme]}. Click to change.`}
      className="rounded-lg px-3 py-1.5 text-sm focus-visible:outline-2"
      style={{ background: "var(--surface)", color: "var(--text-muted)", border: "1px solid var(--border)" }}>
      Theme: {LABEL[theme]}
    </button>
  );
}
```

- [ ] **Step 6: Wrap the app + no-flash script + viewer wiring**

In `src/app/layout.tsx`: wrap `{children}` in `<ThemeProvider>` and add an inline script in `<head>` that sets `data-theme` + the CSS vars before paint to avoid a flash. The script reads `localStorage`/`matchMedia` and applies the same vars (duplicate the minimal logic inline as a string — it must run before React hydrates):

```tsx
// inside <html>, before <body>, add:
<head>
  <script dangerouslySetInnerHTML={{ __html: `
(function(){try{
  var t=localStorage.getItem('darkroomscad-theme');
  var valid=['dark','light','darkroom','high-contrast'];
  if(valid.indexOf(t)<0){t=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';}
  document.documentElement.setAttribute('data-theme',t);
}catch(e){}})();
  `}} />
</head>
```
(The full var application happens in `ThemeProvider`'s effect; the inline script sets `data-theme` early. Keep `theme.css`'s `:root` as the dark default so first paint is dark-correct before JS runs. ThemeProvider overrides per-theme on mount.)

In `src/components/StlViewer.tsx`: read viewer colors from `useTheme()` and pass them to the material/grid/background instead of the hardcoded `#9a9a9a`/`#353535`:

```tsx
import { useTheme } from "./ThemeProvider";
// ...
const { viewer } = useTheme();
// material: <meshStandardMaterial color={viewer.model} .../>
// grid: cellColor={viewer.grid}
// container background: style={{ background: viewer.background, ... }}
```

- [ ] **Step 7: Suite + build**

Run: `npm run test` (theme/resolve + all prior green). `npx tsc --noEmit` clean. `npm run build` compiles.

- [ ] **Step 8: Commit**

```bash
git add src/lib/theme src/components/ThemeProvider.tsx src/components/ThemeToggle.tsx src/app/layout.tsx src/components/StlViewer.tsx
git commit -m "feat(theme): dark/light/darkroom-safelight/high-contrast themes + toggle + viewer wiring"
```

---

### Task 6: Reassemble the page (new controls + format picker + theme toggle + flicker fix)

Integration + the browser gate. Mount the friendly form, the `FilmFormatPicker`, and the `ThemeToggle`; fix the preview re-render flicker; confirm responsive + accessible.

**Files:**
- Modify: `src/components/CarrierForm.tsx` (mount `FilmFormatPicker` for `Film_Format`; render the new controls; keep advanced disclosure)
- Modify: `src/lib/openscad/preview-controller.ts` (carry previous `stl` into the `rendering` state — no blank flicker)
- Test: `src/lib/openscad/preview-controller.test.ts` (assert the previous stl is retained while rendering)
- Modify: `src/app/page.tsx` (header with `ThemeToggle`; pass `Film_Format` value/onChange to the picker)

**Interfaces:**
- Consumes everything from Tasks 1–4 + Plan 2.

- [ ] **Step 1: Fix the preview flicker (carry previous STL while rendering)**

In `preview-controller.ts`, the `rendering` state currently has no `stl`, so the viewer blanks during every re-render. Carry the last successful `stl` forward. First write the failing test (`preview-controller.test.ts`):

```ts
it("keeps the previous stl visible while the next render is in flight", async () => {
  vi.useFakeTimers();
  const d2 = deferred<RenderResult>();
  const render = vi.fn()
    .mockResolvedValueOnce(result([1, 2, 3]))
    .mockReturnValueOnce(d2.promise);
  const seen: (Uint8Array | undefined)[] = [];
  const ctl = new PreviewController({ render }, { debounceMs: 0, onState: (s) => seen.push(s.stl) });
  ctl.request({ n: 1 });
  await vi.advanceTimersByTimeAsync(0); await Promise.resolve(); // first done -> stl [1,2,3]
  ctl.request({ n: 2 });
  await vi.advanceTimersByTimeAsync(0); // second render starts (rendering)
  // While rendering, the emitted stl should still be the previous one, not undefined.
  const renderingState = seen[seen.length - 1];
  expect(renderingState).toEqual(new Uint8Array([1, 2, 3]));
  vi.useRealTimers();
});
```

Run: `npm run test -- preview-controller` → the new test FAILS.

Then implement: track `lastStl` and include it in the `rendering` emission. In `PreviewController`:
- Add `private lastStl: Uint8Array | undefined;`
- On success: `this.lastStl = res.stl;` then emit `{status:"done", stl: res.stl, ...}`.
- In `start()`, change the rendering emit to `this.onState({ status: "rendering", stl: this.lastStl });`.

Run: `npm run test -- preview-controller` → all green (existing tests unaffected; they don't assert `stl` on the rendering state).

- [ ] **Step 2: Mount the format picker + new controls in CarrierForm**

Update `src/components/CarrierForm.tsx` to render the `FilmFormatPicker` for `Film_Format` (the page passes the value/onChange) and otherwise render `Field` per resolved control. The simplest wiring: `CarrierForm` takes an optional `filmFormat` slot it renders at the top of the "Carrier" group. Replace its body:

```tsx
"use client";
import { useState } from "react";
import { Field } from "./controls/Field";
import { FilmFormatPicker } from "./controls/FilmFormatPicker";
import type { ResolvedGroup, FormValue } from "@/lib/form/types";

export function CarrierForm({ groups, values, setValue }: {
  groups: ResolvedGroup[];
  values: Record<string, FormValue>;
  setValue: (param: string, v: FormValue) => void;
}) {
  const [showAdvanced, setShowAdvanced] = useState(false);
  return (
    <div className="space-y-6">
      {groups.map((group) => {
        const fields = group.fields.filter((f) => !f.visibleWhen || f.visibleWhen(values));
        const isAdvanced = fields.length > 0 && fields.every((f) => f.advanced);
        const showPicker = group.title === "Carrier"; // film-format picker lives in the Carrier group
        if (fields.length === 0 && !showPicker) return null;
        if (isAdvanced && !showAdvanced) {
          return (
            <button key={group.title} onClick={() => setShowAdvanced(true)}
              className="text-sm underline" style={{ color: "var(--secondary)" }}>
              Show advanced options
            </button>
          );
        }
        return (
          <section key={group.title} className="rounded-xl p-4"
            style={{ background: "var(--surface)", border: "1px solid var(--border)" }}>
            <h2 className="text-lg mb-3">{group.title}</h2>
            <div className="space-y-3">
              {showPicker && (
                <FilmFormatPicker value={String(values.Film_Format)}
                  onChange={(v) => setValue("Film_Format", v)} />
              )}
              {fields.map((f) => (
                <Field key={f.param} field={f} value={values[f.param]} onChange={(v) => setValue(f.param, v)} />
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
}
```

(`Film_Format` is in `values` because `initialValues` seeds it from the schema default even though it's not in the overlay — verify: it IS, because `useCarrierForm` seeds from `resolveFormModel`+`initialValues`, which only includes overlay params. Since `Film_Format` is no longer in the overlay, it won't be seeded. **Fix:** in `useCarrierForm`, seed `Film_Format` explicitly from the schema default. See Step 3.)

- [ ] **Step 3: Seed Film_Format in the form hook**

In `src/hooks/use-carrier-form.ts`, after `initialValues(groups)`, add the schema default for `Film_Format` (which the overlay no longer carries):

```ts
import schema from "../../generated/param-schema.json";
// ...
const seed = initialValues(groups);
const ff = (schema as ParamSchema).params.find((p) => p.name === "Film_Format");
const [values, setValues] = useState<Record<string, FormValue>>(() => ({
  ...seed,
  Film_Format: (ff?.default as FormValue) ?? "35mm",
}));
```

Ensure `toRenderParams` still sends `Film_Format`: since it's not a visible overlay field, add it to the system params the page injects, OR include it directly. Simplest: the page's `toParams` call includes `Film_Format` via a small change — in `use-carrier-form.ts` `toParams`, merge `Film_Format` into the result:

```ts
const toParams = useCallback(
  (system: Record<string, FormValue>): RenderParams =>
    toRenderParams(groups, values, { Film_Format: values.Film_Format, ...system }),
  [groups, values],
);
```

(Custom_* fields stay gated by `visibleWhen: Film_Format==="custom"` and are sent only when visible — unchanged.)

- [ ] **Step 4: Header + theme toggle in the page**

Update `src/app/page.tsx` header to include the `ThemeToggle` (top-right), keeping the form/viewer/download wiring from Plan 2 intact:

```tsx
import { ThemeToggle } from "@/components/ThemeToggle";
// ...
<header className="mb-6 flex items-start justify-between">
  <div>
    <h1 className="text-3xl font-semibold">DarkroomSCAD</h1>
    <p style={{ color: "var(--text-muted)" }}>Configure your negative carrier and download a print-ready STL.</p>
  </div>
  <ThemeToggle />
</header>
```

- [ ] **Step 5: tsc + build**

Run: `npx tsc --noEmit` (clean) and `npm run build` (compiles). Run `npm run test` (all green, incl. the new flicker test).

- [ ] **Step 6: Manual browser verification (the gate — controller runs this)**

Run `npm run dev`. Load the page. Verify:
1. **Enlarger** renders as cards; selecting a different enlarger re-renders the preview.
2. **Film format** shows aspect-ratio chips (35mm wider than 6×6's square, 4×5 largest); selecting `6×6` re-renders to a square opening; the **Filed edges** switch appears for formats that support it and toggles the preview.
3. **Custom** chip reveals the four dimension sliders.
4. **Orientation / Part / Pegs** are segmented buttons; **Etch a name / Alignment board** are toggle switches; **Font size** is a slider with a live value.
5. The preview **does not blank** during re-render (previous model stays under the "rendering…" overlay).
6. **Theme toggle** cycles Dark → Light → Safelight (red on black) → High-contrast; the form AND the 3D viewer colors change; the choice persists across reload with no flash.
7. Keyboard: every control is tabbable with a visible focus ring; switches toggle on Space/Enter.
Capture screenshots of at least the default dark view and the safelight theme.

- [ ] **Step 7: Commit + push**

```bash
git add src/components/CarrierForm.tsx src/hooks/use-carrier-form.ts src/lib/openscad/preview-controller.ts src/lib/openscad/preview-controller.test.ts src/app/page.tsx
git commit -m "feat(ui): assemble friendly customizer — format picker, controls, theme toggle, no-flicker preview"
git push origin main
```

---

## Plan 3 Self-Review

- **Spec/brief coverage:** friendly control kit — segmented/switch/slider/cards (Task 1) ✓; signature film-format aspect-ratio picker with filed/custom (Task 2) ✓; carrier-outline SVGs + enlarger cards showing each carrier's silhouette (Task 3) ✓; overlay rewritten to friendly controls (Task 4) ✓; full theme system (dark/light/darkroom-safelight/high-contrast) + toggle + persistence + no-flash + viewer wiring (Task 5) ✓; page integration + flicker fix + a11y + browser gate (Task 6) ✓. Export + Vercel deploy correctly deferred to Plan 4.
- **Placeholder scan:** complete code in every step. Two flagged judgment points are explicit, not hand-waved: (a) slider bounds for bare-number params default to 0..100 and the implementer must report any param needing negatives (offsets) so the controller can keep it a `number` control; (b) `Film_Format` seeding/sending is handled in `useCarrierForm` since it left the overlay.
- **Type consistency:** `ControlKind` extended once (Task 1) and consumed by `Field`/overlay/tests. `FormValue`/`ResolvedField` reused from Plan 2 unchanged. `ThemeName`/`ThemeTokens`/`THEMES` defined in Task 4 and consumed by provider/toggle/viewer. `toFilmFormatValue`/`fromFilmFormatValue` consistent (Tasks 2,5). `coerceOptionValue` shared by Segmented/CardSelect/select (Task 1). `PreviewState.stl` now also populated in the `rendering` state (Task 5) — backward compatible with Plan 2 consumers.

## Notes for the executor

- **`Film_Format` left the overlay** and is rendered by `FilmFormatPicker`. The two consequences (seed it in the hook's initial values; include it in `toParams`) are handled in Task 5 Steps 2–3. Double-check the consistency test (`carrier-ui.test.ts`) asserts its absence (Task 3 Step 2).
- **Negative offsets:** the `*_Offset` params can be negative in OpenSCAD; the default slider min of 0 would clamp them. In Task 3 you flagged these — the pragmatic call is to keep the offset params as `number` controls (not sliders) OR give `Slider` an explicit symmetric range via the overlay. Pick one and note it; do not silently lose negative offsets.
- **Darkroom-safelight theme** is the distinctive, on-subject theme (usable under an actual red safelight). It is intentionally monochrome-red; do not "fix" its low contrast — that is the point.
- **No-flash:** the inline head script sets `data-theme` before paint; `ThemeProvider` applies the full var set on mount. Keep `theme.css :root` as the dark defaults so the very first paint is dark-correct.
