# DarkroomSCAD Web — Plan 2: Guided Customizer UI & Live Preview

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Plan 1 render core into a guided, no-code customizer: photographers pick options from clean form controls (auto-generated from the carrier's parameter schema), see a live 3D preview that updates as they change parameters, and download an STL.

**Architecture:** A hand-maintained **curation overlay** (`carrier-ui.ts`) maps the generated `param-schema.json` into user-facing groups/fields with labels, help, conditional visibility, and an "Advanced" tier. A pure form-state layer produces `RenderParams`; a **preview controller** debounces changes and coalesces to the latest render (drop-stale, newest-wins) via the Plan 1 `RenderClient`; a **react-three-fiber** viewer shows the resulting STL. Baseline dorkroom-aligned dark styling (full multi-theme system is Plan 3).

**Tech Stack:** Next.js 15 (App Router) + TypeScript, React 19, Tailwind CSS v4, `three` + `@react-three/fiber` + `@react-three/drei`, Vitest. Engine: vendored OpenSCAD 2025.03.25 WASM (Manifold).

## Global Constraints

- **Repo:** all work in `~/workspace/darkroomscad-web` (Plan 1 complete, on `main`, remote `origin` = github.com/narrowstacks/darkroomscad-web).
- **No backend.** All rendering stays client-side WASM in the Plan 1 Web Worker. The app stays effectively static.
- **Reuse Plan 1, don't fork it.** Consume `RenderClient` (`src/lib/openscad/client.ts`), `RenderRequest`/`RenderResult`/`RenderParams`/`RenderQuality` (`src/lib/openscad/types.ts`), `parseCustomizer`/`Param`/`ParamSchema` (`src/lib/params/`), `generated/param-schema.json`, and `BUNDLED_FONTS`/`DEFAULT_FONT_FAMILY` (`src/config/fonts.ts`). Do not change `render.ts` render args or `worker.ts` protocol.
- **Engine quality control:** preview renders set the **`Render_Quality` param to `"preview"`** (carrier.scad maps that to `$fn=32`, faster); the download sets `Render_Quality="final"` (`$fn=100`). `Render_Quality` is **system-managed and hidden from the form**.
- **Fonts:** the `Fontface` control is a dropdown sourced from `BUNDLED_FONTS` (currently just `Liberation Mono`); default is `DEFAULT_FONT_FAMILY`. Never a free-text font field (only bundled fonts render).
- **Proprietary font default:** the schema's `Fontface` default (`Lucida Console`) must be overridden to `DEFAULT_FONT_FAMILY` in the form's initial values.
- **Visual language (dorkroom-aligned, baseline only this plan):** Fraunces (display/headings) + Montserrat (UI/body); dark surface palette — bg `#09090b`, surfaces `#121214`/`#1c1c1f`, accents mint `#6ef3a4` (primary), sky `#7dd6ff`, coral `#f99f96`, lime `#e5ff7d`; text `#ffffff`→`#a1a1aa`→`#71717a`; borders `rgba(255,255,255,0.1)`. Viewer materials: model `#9a9a9a`, grid/edges `#353535`. Semantic: error = coral, success = mint. (Full theme toggle + light/safelight/high-contrast = Plan 3.)
- **Deferred to Plan 3 (do NOT build here):** ZIP / multi-part export + part enumeration; full theme system & toggle; comprehensive error-UX surfaces; Vercel deploy + the `prebuild` CI fix. Plan 2 ships a single-STL "Download" bridge button (current part, full quality).

---

### Task 1: 3D/UI dependencies + dorkroom base theme

Foundational setup the viewer and page depend on. No new logic; deliverable verified by build + a visible themed page.

**Files:**
- Modify: `package.json` (add `three`, `@react-three/fiber`, `@react-three/drei`, `@types/three`)
- Create: `src/app/theme.css` (CSS custom properties — the dorkroom dark tokens)
- Modify: `src/app/globals.css` (import theme.css; base body styles)
- Modify: `src/app/layout.tsx` (load Fraunces + Montserrat via `next/font/google`; apply font CSS vars)

**Interfaces:**
- Produces: CSS variables `--bg`, `--surface`, `--surface-muted`, `--border`, `--text`, `--text-muted`, `--text-dim`, `--primary`, `--secondary`, `--accent`, `--highlight`, `--error`, `--viewer-model`, `--viewer-grid`; font vars `--font-display`, `--font-sans`.

- [ ] **Step 1: Install dependencies**

```bash
cd ~/workspace/darkroomscad-web
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three
```

- [ ] **Step 2: Create the theme tokens**

Create `src/app/theme.css`:

```css
:root {
  --bg: #09090b;
  --surface: #121214;
  --surface-muted: #1c1c1f;
  --border: rgba(255, 255, 255, 0.1);
  --border-strong: rgba(255, 255, 255, 0.2);
  --text: #ffffff;
  --text-muted: #a1a1aa;
  --text-dim: #71717a;
  --primary: #6ef3a4;
  --secondary: #7dd6ff;
  --accent: #f99f96;
  --highlight: #e5ff7d;
  --error: #f99f96;
  --success: #6ef3a4;
  --viewer-model: #9a9a9a;
  --viewer-grid: #353535;
}
```

- [ ] **Step 3: Wire fonts + globals**

Replace `src/app/layout.tsx` with (keeps Next metadata, adds the two Google fonts as CSS vars):

```tsx
import type { Metadata } from "next";
import { Fraunces, Montserrat } from "next/font/google";
import "./globals.css";

const fraunces = Fraunces({ subsets: ["latin"], variable: "--font-display", display: "swap" });
const montserrat = Montserrat({ subsets: ["latin"], variable: "--font-sans", display: "swap" });

export const metadata: Metadata = {
  title: "DarkroomSCAD — Negative Carrier Customizer",
  description: "Configure and export 3D-printable darkroom negative carriers, rendered in your browser.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${fraunces.variable} ${montserrat.variable}`}>
      <body>{children}</body>
    </html>
  );
}
```

Replace `src/app/globals.css` with:

```css
@import "tailwindcss";
@import "./theme.css";

body {
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans), ui-sans-serif, system-ui, sans-serif;
}

h1, h2, h3 {
  font-family: var(--font-display), Georgia, serif;
}
```

- [ ] **Step 4: Verify build + a themed page renders**

Run: `npm run build`
Expected: compiles successfully, no errors.
Run: `npm run dev` then load the page — body is near-black `#09090b`, headings use a serif. (The page content is still the Plan 1 render-core button; that's replaced in Task 6.)

- [ ] **Step 5: Commit**

```bash
git add package.json package-lock.json src/app/theme.css src/app/globals.css src/app/layout.tsx
git commit -m "feat(ui): add three/r3f/drei deps and dorkroom dark theme tokens + fonts"
```

---

### Task 2: Curation overlay + form-model resolver + consistency check

Pure logic — full TDD. Maps the generated schema into a clean, user-facing form model and guards against schema drift.

**Files:**
- Create: `src/config/carrier-ui.ts` (the hand-maintained overlay)
- Create: `src/lib/form/form-model.ts` (resolver + validator)
- Create: `src/lib/form/types.ts`
- Test: `src/lib/form/form-model.test.ts`

**Interfaces:**
- Consumes: `ParamSchema`/`Param` from `src/lib/params/types.ts`; `BUNDLED_FONTS` from `src/config/fonts.ts`.
- Produces:
  - `type ControlKind = "select" | "number" | "text" | "toggle"`
  - `interface FieldConfig { param: string; label: string; help?: string; advanced?: boolean; control?: ControlKind; optionsFrom?: "fonts"; visibleWhen?: (v: Record<string, FormValue>) => boolean }`
  - `interface GroupConfig { title: string; fields: FieldConfig[] }`
  - `type FormValue = string | number | boolean`
  - `interface ResolvedField { param: string; label: string; help?: string; advanced: boolean; control: ControlKind; options?: { value: string | number; label: string }[]; min?: number; max?: number; step?: number; default: FormValue; visibleWhen?: (v: Record<string, FormValue>) => boolean }`
  - `interface ResolvedGroup { title: string; fields: ResolvedField[] }`
  - `const CARRIER_UI: GroupConfig[]`
  - `function resolveFormModel(schema: ParamSchema, ui: GroupConfig[]): ResolvedGroup[]`
  - `function validateOverlay(schema: ParamSchema, ui: GroupConfig[]): string[]` (returns list of error strings; empty = OK)
  - `const SYSTEM_DEFAULT_OVERRIDES: Record<string, FormValue>` (e.g. `{ Fontface: DEFAULT_FONT_FAMILY }`)

- [ ] **Step 1: Write the types**

Create `src/lib/form/types.ts`:

```ts
export type ControlKind = "select" | "number" | "text" | "toggle";
export type FormValue = string | number | boolean;

export interface FieldConfig {
  param: string;
  label: string;
  help?: string;
  advanced?: boolean;
  control?: ControlKind;
  optionsFrom?: "fonts";
  visibleWhen?: (values: Record<string, FormValue>) => boolean;
}

export interface GroupConfig {
  title: string;
  fields: FieldConfig[];
}

export interface ResolvedField {
  param: string;
  label: string;
  help?: string;
  advanced: boolean;
  control: ControlKind;
  options?: { value: string | number; label: string }[];
  min?: number;
  max?: number;
  step?: number;
  default: FormValue;
  visibleWhen?: (values: Record<string, FormValue>) => boolean;
}

export interface ResolvedGroup {
  title: string;
  fields: ResolvedField[];
}
```

- [ ] **Step 2: Write the failing tests**

Create `src/lib/form/form-model.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { resolveFormModel, validateOverlay } from "./form-model";
import type { GroupConfig } from "./types";
import type { ParamSchema } from "../params/types";

const schema: ParamSchema = {
  params: [
    { name: "Carrier_Type", section: "Carrier Type", type: "enum", default: "omega-d", hidden: false,
      options: [{ value: "omega-d", label: "omega-d" }, { value: "beseler-23c", label: "beseler-23c" }] },
    { name: "Font_Size", section: "x", type: "number", default: 10, min: 6, max: 40, step: 0.5, hidden: false },
    { name: "Owner_Name", section: "x", type: "string", default: "NAME", hidden: false },
    { name: "Fontface", section: "x", type: "string", default: "Lucida Console", hidden: false },
    { name: "Alignment_Board", section: "x", type: "boolean", default: true, hidden: false },
  ],
};

describe("resolveFormModel", () => {
  it("merges schema type/default/options/range into resolved fields and derives control kind", () => {
    const ui: GroupConfig[] = [{ title: "Main", fields: [
      { param: "Carrier_Type", label: "Enlarger" },
      { param: "Font_Size", label: "Text size" },
      { param: "Owner_Name", label: "Your name" },
      { param: "Alignment_Board", label: "Alignment board" },
    ] }];
    const [group] = resolveFormModel(schema, ui);
    expect(group.title).toBe("Main");
    const byParam = Object.fromEntries(group.fields.map((f) => [f.param, f]));
    expect(byParam.Carrier_Type).toMatchObject({ control: "select", default: "omega-d" });
    expect(byParam.Carrier_Type.options).toHaveLength(2);
    expect(byParam.Font_Size).toMatchObject({ control: "number", default: 10, min: 6, max: 40, step: 0.5 });
    expect(byParam.Owner_Name).toMatchObject({ control: "text", default: "NAME" });
    expect(byParam.Alignment_Board).toMatchObject({ control: "toggle", default: true });
  });

  it("sources Fontface options from BUNDLED_FONTS and applies the default override", () => {
    const ui: GroupConfig[] = [{ title: "Text", fields: [
      { param: "Fontface", label: "Font", control: "select", optionsFrom: "fonts" },
    ] }];
    const [group] = resolveFormModel(schema, ui);
    const f = group.fields[0];
    expect(f.control).toBe("select");
    expect(f.options?.length).toBeGreaterThanOrEqual(1);
    expect(f.options?.map((o) => o.value)).toContain("Liberation Mono");
    // Proprietary schema default is overridden to a bundled face
    expect(f.default).toBe("Liberation Mono");
  });

  it("carries advanced flag and visibleWhen through", () => {
    const ui: GroupConfig[] = [{ title: "Adv", fields: [
      { param: "Font_Size", label: "Size", advanced: true, visibleWhen: (v) => v.Alignment_Board === true },
    ] }];
    const f = resolveFormModel(schema, ui)[0].fields[0];
    expect(f.advanced).toBe(true);
    expect(f.visibleWhen?.({ Alignment_Board: true })).toBe(true);
    expect(f.visibleWhen?.({ Alignment_Board: false })).toBe(false);
  });
});

describe("validateOverlay", () => {
  it("returns no errors when every referenced param exists", () => {
    const ui: GroupConfig[] = [{ title: "M", fields: [{ param: "Carrier_Type", label: "x" }] }];
    expect(validateOverlay(schema, ui)).toEqual([]);
  });

  it("flags overlay fields referencing a param missing from the schema", () => {
    const ui: GroupConfig[] = [{ title: "M", fields: [{ param: "Nonexistent_Param", label: "x" }] }];
    const errors = validateOverlay(schema, ui);
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain("Nonexistent_Param");
  });
});
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `npm run test -- form-model`
Expected: FAIL — `resolveFormModel`/`validateOverlay` not defined.

- [ ] **Step 4: Implement the resolver + validator**

Create `src/lib/form/form-model.ts`:

```ts
import type { ParamSchema, Param, ParamType } from "../params/types";
import { BUNDLED_FONTS, DEFAULT_FONT_FAMILY } from "../../config/fonts";
import type { ControlKind, FormValue, GroupConfig, ResolvedField, ResolvedGroup } from "./types";

export const SYSTEM_DEFAULT_OVERRIDES: Record<string, FormValue> = {
  Fontface: DEFAULT_FONT_FAMILY,
};

function controlForType(type: ParamType): ControlKind {
  switch (type) {
    case "enum": return "select";
    case "number": return "number";
    case "boolean": return "toggle";
    default: return "text";
  }
}

function fontOptions(): { value: string; label: string }[] {
  return BUNDLED_FONTS.map((f) => ({ value: f.family, label: f.family }));
}

export function resolveFormModel(schema: ParamSchema, ui: GroupConfig[]): ResolvedGroup[] {
  const byName = new Map<string, Param>(schema.params.map((p) => [p.name, p]));
  return ui.map((group) => ({
    title: group.title,
    fields: group.fields.map((fc): ResolvedField => {
      const p = byName.get(fc.param);
      if (!p) throw new Error(`carrier-ui references unknown param "${fc.param}"`);
      const control = fc.control ?? controlForType(p.type);
      const options = fc.optionsFrom === "fonts" ? fontOptions() : p.options;
      const override = SYSTEM_DEFAULT_OVERRIDES[fc.param];
      return {
        param: fc.param,
        label: fc.label,
        help: fc.help,
        advanced: fc.advanced ?? false,
        control,
        options,
        min: p.min,
        max: p.max,
        step: p.step,
        default: override !== undefined ? override : p.default,
        visibleWhen: fc.visibleWhen,
      };
    }),
  }));
}

export function validateOverlay(schema: ParamSchema, ui: GroupConfig[]): string[] {
  const names = new Set(schema.params.map((p) => p.name));
  const errors: string[] = [];
  for (const group of ui) {
    for (const field of group.fields) {
      if (!names.has(field.param)) {
        errors.push(`carrier-ui group "${group.title}" references unknown param "${field.param}"`);
      }
    }
  }
  return errors;
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `npm run test -- form-model`
Expected: PASS.

- [ ] **Step 6: Author the real curation overlay**

Create `src/config/carrier-ui.ts` (the hand-curated UX — primary fields visible, advanced collapsed, conditional visibility, fonts dropdown). `Render_Quality`, `_WhichPart`, custom-format conditionals, and multi-material conditionals are encoded here:

```ts
import type { GroupConfig, FormValue } from "../lib/form/types";

const isCustomFormat = (v: Record<string, FormValue>) => v.Film_Format === "custom";

export const CARRIER_UI: GroupConfig[] = [
  {
    title: "Carrier",
    fields: [
      { param: "Carrier_Type", label: "Enlarger", help: "Which enlarger this carrier fits." },
      { param: "Film_Format", label: "Film format" },
      { param: "Orientation", label: "Orientation", help: "Ignored for 4x5." },
      { param: "Top_or_Bottom", label: "Part", help: "A full carrier needs both top and bottom printed." },
    ],
  },
  {
    title: "Custom film format",
    fields: [
      { param: "Custom_Film_Width", label: "Film width (mm)", visibleWhen: isCustomFormat },
      { param: "Custom_Film_Height", label: "Film height (mm)", visibleWhen: isCustomFormat },
      { param: "Custom_Opening_Width", label: "Opening width (mm)", visibleWhen: isCustomFormat },
      { param: "Custom_Opening_Height", label: "Opening height (mm)", visibleWhen: isCustomFormat },
    ],
  },
  {
    title: "Text",
    fields: [
      { param: "Enable_Owner_Name_Etch", label: "Etch a name" },
      { param: "Owner_Name", label: "Name", visibleWhen: (v) => v.Enable_Owner_Name_Etch === true },
      { param: "Enable_Type_Name_Etch", label: "Etch the carrier type" },
      { param: "Type_Name", label: "Type label source", visibleWhen: (v) => v.Enable_Type_Name_Etch === true },
      { param: "Custom_Type_Name", label: "Custom type label",
        visibleWhen: (v) => v.Enable_Type_Name_Etch === true && v.Type_Name === "Custom" },
      { param: "Fontface", label: "Font", control: "select", optionsFrom: "fonts" },
      { param: "Font_Size", label: "Font size" },
    ],
  },
  {
    title: "Options",
    fields: [
      { param: "Alignment_Board", label: "Include alignment board" },
      { param: "Alignment_Board_Type", label: "Alignment board type",
        visibleWhen: (v) => v.Alignment_Board === true },
      { param: "Printed_or_Heat_Set_Pegs", label: "Pegs",
        help: "Heat-set required when including the alignment board." },
      { param: "Flip_Bottom_For_Printing", label: "Flip bottom for printing" },
    ],
  },
  {
    title: "Advanced",
    fields: [
      { param: "TEXT_ETCH_DEPTH", label: "Etch depth (mm)", advanced: true },
      { param: "Owner_Text_X_Offset", label: "Name X offset", advanced: true },
      { param: "Owner_Text_Y_Offset", label: "Name Y offset", advanced: true },
      { param: "Type_Text_X_Offset", label: "Type X offset", advanced: true },
      { param: "Type_Text_Y_Offset", label: "Type Y offset", advanced: true },
      { param: "Peg_Gap", label: "Peg gap (mm)", advanced: true },
      { param: "Adjust_Film_Width", label: "Adjust film width (mm)", advanced: true },
      { param: "Adjust_Film_Height", label: "Adjust film height (mm)", advanced: true },
      { param: "Text_As_Separate_Parts", label: "Separate text parts (multi-material)", advanced: true },
      { param: "Layer_Height_mm", label: "Layer height (mm)", advanced: true,
        visibleWhen: (v) => v.Text_As_Separate_Parts === true },
      { param: "Text_Layer_Multiple", label: "Text layers", advanced: true,
        visibleWhen: (v) => v.Text_As_Separate_Parts === true },
    ],
  },
];
```

- [ ] **Step 7: Add the consistency check as a test (fails the build on schema drift)**

Create `src/config/carrier-ui.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { CARRIER_UI } from "./carrier-ui";
import { validateOverlay, resolveFormModel } from "../lib/form/form-model";
import schema from "../../generated/param-schema.json";
import type { ParamSchema } from "../lib/params/types";

describe("carrier-ui overlay vs generated schema", () => {
  it("references only params that exist in the generated schema", () => {
    expect(validateOverlay(schema as ParamSchema, CARRIER_UI)).toEqual([]);
  });
  it("resolves every field against the real schema without throwing", () => {
    expect(() => resolveFormModel(schema as ParamSchema, CARRIER_UI)).not.toThrow();
  });
});
```

Ensure `resolveJsonModule` is enabled in `tsconfig.json` (Next defaults to `true`; if the import errors, add `"resolveJsonModule": true` to `compilerOptions`).

- [ ] **Step 8: Run the full form suite + tsc**

Run: `npm run test -- form-model carrier-ui`
Expected: PASS (resolver/validator + the real-schema consistency check).
Run: `npx tsc --noEmit`
Expected: clean.

- [ ] **Step 9: Commit**

```bash
git add src/lib/form src/config/carrier-ui.ts src/config/carrier-ui.test.ts
git commit -m "feat(form): curation overlay, form-model resolver, schema-drift consistency check"
```

---

### Task 3: Form state hook + control components

The interactive form: holds values, applies defaults + system overrides, computes which fields are visible, and produces `RenderParams`. Form-state logic is pure and TDD'd; controls are thin presentational components.

**Files:**
- Create: `src/lib/form/form-state.ts` (pure helpers — defaults, visibility, toRenderParams)
- Test: `src/lib/form/form-state.test.ts`
- Create: `src/components/controls/Field.tsx` (renders one ResolvedField → the right control)
- Create: `src/components/CarrierForm.tsx` (groups, advanced disclosure, wires values)
- Create: `src/hooks/use-carrier-form.ts` (React state wrapper around form-state)

**Interfaces:**
- Consumes: `ResolvedGroup`/`ResolvedField`/`FormValue` from `src/lib/form/types.ts`; `RenderParams` from `src/lib/openscad/types.ts`.
- Produces:
  - `function initialValues(groups: ResolvedGroup[]): Record<string, FormValue>`
  - `function visibleFields(groups: ResolvedGroup[], values: Record<string, FormValue>): ResolvedField[]`
  - `function toRenderParams(groups: ResolvedGroup[], values: Record<string, FormValue>, system: Record<string, FormValue>): RenderParams` — includes only currently-visible fields' values, plus the `system` overrides (e.g. `Render_Quality`).
  - `function useCarrierForm(): { groups: ResolvedGroup[]; values; setValue(param,value); toParams(system) }`

- [ ] **Step 1: Write the failing tests for form-state**

Create `src/lib/form/form-state.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { initialValues, visibleFields, toRenderParams } from "./form-state";
import type { ResolvedGroup } from "./types";

const groups: ResolvedGroup[] = [
  { title: "G", fields: [
    { param: "A", label: "A", advanced: false, control: "text", default: "x" },
    { param: "B", label: "B", advanced: false, control: "number", default: 5,
      visibleWhen: (v) => v.A === "show" },
  ] },
];

describe("form-state", () => {
  it("initialValues collects each field's default", () => {
    expect(initialValues(groups)).toEqual({ A: "x", B: 5 });
  });

  it("visibleFields hides fields whose visibleWhen is false", () => {
    expect(visibleFields(groups, { A: "x", B: 5 }).map((f) => f.param)).toEqual(["A"]);
    expect(visibleFields(groups, { A: "show", B: 5 }).map((f) => f.param)).toEqual(["A", "B"]);
  });

  it("toRenderParams emits only visible fields plus system overrides", () => {
    const hidden = toRenderParams(groups, { A: "x", B: 5 }, { Render_Quality: "preview" });
    expect(hidden).toEqual({ A: "x", Render_Quality: "preview" }); // B hidden
    const shown = toRenderParams(groups, { A: "show", B: 5 }, { Render_Quality: "final" });
    expect(shown).toEqual({ A: "show", B: 5, Render_Quality: "final" });
  });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `npm run test -- form-state`
Expected: FAIL — not defined.

- [ ] **Step 3: Implement form-state**

Create `src/lib/form/form-state.ts`:

```ts
import type { FormValue, ResolvedField, ResolvedGroup } from "./types";
import type { RenderParams } from "../openscad/types";

export function initialValues(groups: ResolvedGroup[]): Record<string, FormValue> {
  const out: Record<string, FormValue> = {};
  for (const g of groups) for (const f of g.fields) out[f.param] = f.default;
  return out;
}

export function visibleFields(
  groups: ResolvedGroup[],
  values: Record<string, FormValue>,
): ResolvedField[] {
  const out: ResolvedField[] = [];
  for (const g of groups) {
    for (const f of g.fields) {
      if (!f.visibleWhen || f.visibleWhen(values)) out.push(f);
    }
  }
  return out;
}

export function toRenderParams(
  groups: ResolvedGroup[],
  values: Record<string, FormValue>,
  system: Record<string, FormValue>,
): RenderParams {
  const params: RenderParams = {};
  for (const f of visibleFields(groups, values)) params[f.param] = values[f.param];
  return { ...params, ...system };
}
```

- [ ] **Step 4: Run to verify pass**

Run: `npm run test -- form-state`
Expected: PASS.

- [ ] **Step 5: Build the control component**

Create `src/components/controls/Field.tsx` (presentational; one component switches on `control`). Styling uses the theme CSS vars:

```tsx
"use client";
import type { ResolvedField, FormValue } from "@/lib/form/types";

export function Field({ field, value, onChange }: {
  field: ResolvedField;
  value: FormValue;
  onChange: (v: FormValue) => void;
}) {
  const id = `field-${field.param}`;
  const labelEl = (
    <label htmlFor={id} className="block text-sm font-medium" style={{ color: "var(--text)" }}>
      {field.label}
    </label>
  );
  const help = field.help ? (
    <p className="text-xs mt-0.5" style={{ color: "var(--text-dim)" }}>{field.help}</p>
  ) : null;

  if (field.control === "toggle") {
    return (
      <div className="flex items-center gap-3 py-1">
        <input id={id} type="checkbox" checked={value === true}
          onChange={(e) => onChange(e.target.checked)} />
        <div>{labelEl}{help}</div>
      </div>
    );
  }

  const inputStyle = {
    background: "var(--surface-muted)", color: "var(--text)",
    border: "1px solid var(--border)",
  } as const;

  return (
    <div className="py-1">
      {labelEl}{help}
      {field.control === "select" ? (
        <select id={id} value={String(value)} onChange={(e) => {
          const opt = field.options?.find((o) => String(o.value) === e.target.value);
          onChange(opt ? opt.value : e.target.value);
        }} className="mt-1 w-full rounded px-2 py-1.5 text-sm" style={inputStyle}>
          {field.options?.map((o) => (
            <option key={String(o.value)} value={String(o.value)}>{o.label}</option>
          ))}
        </select>
      ) : field.control === "number" ? (
        <input id={id} type="number" value={Number(value)}
          min={field.min} max={field.max} step={field.step ?? "any"}
          onChange={(e) => onChange(e.target.value === "" ? 0 : Number(e.target.value))}
          className="mt-1 w-full rounded px-2 py-1.5 text-sm" style={inputStyle} />
      ) : (
        <input id={id} type="text" value={String(value)}
          onChange={(e) => onChange(e.target.value)}
          className="mt-1 w-full rounded px-2 py-1.5 text-sm" style={inputStyle} />
      )}
    </div>
  );
}
```

- [ ] **Step 6: Build the form hook + CarrierForm**

Create `src/hooks/use-carrier-form.ts`:

```ts
"use client";
import { useMemo, useState, useCallback } from "react";
import { CARRIER_UI } from "@/config/carrier-ui";
import { resolveFormModel } from "@/lib/form/form-model";
import { initialValues, toRenderParams } from "@/lib/form/form-state";
import schema from "../../generated/param-schema.json";
import type { ParamSchema } from "@/lib/params/types";
import type { FormValue } from "@/lib/form/types";
import type { RenderParams } from "@/lib/openscad/types";

export function useCarrierForm() {
  const groups = useMemo(() => resolveFormModel(schema as ParamSchema, CARRIER_UI), []);
  const [values, setValues] = useState<Record<string, FormValue>>(() => initialValues(groups));
  const setValue = useCallback((param: string, value: FormValue) => {
    setValues((prev) => ({ ...prev, [param]: value }));
  }, []);
  const toParams = useCallback(
    (system: Record<string, FormValue>): RenderParams => toRenderParams(groups, values, system),
    [groups, values],
  );
  return { groups, values, setValue, toParams };
}
```

Create `src/components/CarrierForm.tsx` (renders groups; "Advanced" group collapses; respects `visibleWhen`):

```tsx
"use client";
import { useState } from "react";
import { Field } from "./controls/Field";
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
        if (fields.length === 0) return null;
        const isAdvanced = fields.every((f) => f.advanced);
        if (isAdvanced && !showAdvanced) {
          return (
            <button key={group.title} onClick={() => setShowAdvanced(true)}
              className="text-sm underline" style={{ color: "var(--secondary)" }}>
              Show advanced options
            </button>
          );
        }
        return (
          <section key={group.title} className="rounded-lg p-4"
            style={{ background: "var(--surface)", border: "1px solid var(--border)" }}>
            <h2 className="text-lg mb-2">{group.title}</h2>
            <div className="space-y-2">
              {fields.map((f) => (
                <Field key={f.param} field={f} value={values[f.param]}
                  onChange={(v) => setValue(f.param, v)} />
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
}
```

- [ ] **Step 7: Run suite + build**

Run: `npm run test`
Expected: all pass (form-state + earlier).
Run: `npm run build`
Expected: compiles (the components aren't mounted yet — Task 6 mounts them; this confirms they type-check/bundle).

- [ ] **Step 8: Commit**

```bash
git add src/lib/form/form-state.ts src/lib/form/form-state.test.ts src/components/controls/Field.tsx src/components/CarrierForm.tsx src/hooks/use-carrier-form.ts
git commit -m "feat(form): form-state, controls, and CarrierForm with conditional visibility"
```

---

### Task 4: Preview controller (debounced + coalesced, newest-wins)

Pure-logic coordinator with full TDD. Debounces parameter changes and ensures only the latest render's result is applied (drop-stale). True mid-render WASM interruption isn't possible (callMain can't be aborted), so "cancellation" = debounce + generation-guarded results + coalesce-to-latest pending request.

**Files:**
- Create: `src/lib/openscad/preview-controller.ts`
- Test: `src/lib/openscad/preview-controller.test.ts`

**Interfaces:**
- Consumes: `RenderClient` (`render(req): Promise<RenderResult>`), `RenderParams`, `RenderResult`.
- Produces:
  - `interface PreviewState { status: "idle" | "rendering" | "done" | "error"; stl?: Uint8Array; error?: string; durationMs?: number }`
  - `class PreviewController { constructor(client: { render(req): Promise<RenderResult> }, opts?: { debounceMs?: number; onState: (s: PreviewState) => void }); request(params: RenderParams): void; dispose(): void }`
  - Behavior: `request()` schedules a debounced render with `Render_Quality:"preview"` already in `params`; each render gets an incrementing generation id; when a render resolves, its result is applied ONLY if it is the latest generation (stale results dropped). While a render is in flight, the newest `request()` is remembered and fired when the in-flight one settles (coalescing — no queue buildup).

- [ ] **Step 1: Write the failing tests**

Create `src/lib/openscad/preview-controller.test.ts`:

```ts
import { describe, it, expect, vi } from "vitest";
import { PreviewController } from "./preview-controller";
import type { RenderResult } from "./types";

function deferred<T>() {
  let resolve!: (v: T) => void, reject!: (e: unknown) => void;
  const promise = new Promise<T>((res, rej) => { resolve = res; reject = rej; });
  return { promise, resolve, reject };
}

const result = (stl: number[]): RenderResult => ({ stl: new Uint8Array(stl), log: "", durationMs: 1 });

describe("PreviewController", () => {
  it("debounces rapid requests into a single render", async () => {
    vi.useFakeTimers();
    const render = vi.fn().mockResolvedValue(result([1]));
    const states: string[] = [];
    const ctl = new PreviewController({ render }, { debounceMs: 100, onState: (s) => states.push(s.status) });
    ctl.request({ A: 1 }); ctl.request({ A: 2 }); ctl.request({ A: 3 });
    expect(render).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(100);
    expect(render).toHaveBeenCalledTimes(1);
    expect(render.mock.calls[0][0].params).toEqual({ A: 3 }); // latest wins
    vi.useRealTimers();
  });

  it("drops a stale result when a newer render supersedes it", async () => {
    vi.useFakeTimers();
    const d1 = deferred<RenderResult>();
    const d2 = deferred<RenderResult>();
    const render = vi.fn()
      .mockReturnValueOnce(d1.promise)
      .mockReturnValueOnce(d2.promise);
    let last: Uint8Array | undefined;
    const ctl = new PreviewController({ render }, { debounceMs: 0, onState: (s) => { if (s.stl) last = s.stl; } });
    ctl.request({ n: 1 });
    await vi.advanceTimersByTimeAsync(0);          // fires render #1 (in flight)
    ctl.request({ n: 2 });                          // newest pending while #1 in flight
    d1.resolve(result([11]));                        // #1 settles -> stale path + fires #2
    await Promise.resolve(); await vi.advanceTimersByTimeAsync(0);
    d2.resolve(result([22]));                        // #2 settles -> applied
    await Promise.resolve();
    expect(last).toEqual(new Uint8Array([22]));      // never [11]
    vi.useRealTimers();
  });

  it("reports error state when a render rejects", async () => {
    vi.useFakeTimers();
    const render = vi.fn().mockRejectedValue(new Error("boom"));
    let errState: string | undefined;
    const ctl = new PreviewController({ render }, { debounceMs: 0, onState: (s) => { if (s.status === "error") errState = s.error; } });
    ctl.request({ A: 1 });
    await vi.advanceTimersByTimeAsync(0); await Promise.resolve();
    expect(errState).toBe("boom");
    vi.useRealTimers();
  });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `npm run test -- preview-controller`
Expected: FAIL — not defined.

- [ ] **Step 3: Implement the controller**

Create `src/lib/openscad/preview-controller.ts`:

```ts
import type { RenderParams, RenderResult } from "./types";

export interface PreviewState {
  status: "idle" | "rendering" | "done" | "error";
  stl?: Uint8Array;
  error?: string;
  durationMs?: number;
}

interface RenderLike {
  render(req: { params: RenderParams; quality: "preview" | "final" }): Promise<RenderResult>;
}

export class PreviewController {
  private client: RenderLike;
  private debounceMs: number;
  private onState: (s: PreviewState) => void;
  private timer: ReturnType<typeof setTimeout> | null = null;
  private generation = 0;       // increments per render started
  private inFlight = false;
  private pending: RenderParams | null = null;  // newest params awaiting an idle client
  private disposed = false;

  constructor(client: RenderLike, opts: { debounceMs?: number; onState: (s: PreviewState) => void }) {
    this.client = client;
    this.debounceMs = opts.debounceMs ?? 400;
    this.onState = opts.onState;
  }

  request(params: RenderParams): void {
    if (this.disposed) return;
    if (this.timer) clearTimeout(this.timer);
    this.timer = setTimeout(() => {
      this.timer = null;
      this.start(params);
    }, this.debounceMs);
  }

  private start(params: RenderParams): void {
    if (this.inFlight) { this.pending = params; return; }  // coalesce: remember newest
    this.inFlight = true;
    const gen = ++this.generation;
    this.onState({ status: "rendering" });
    this.client.render({ params, quality: "preview" }).then(
      (res) => this.settle(gen, () => this.onState({ status: "done", stl: res.stl, durationMs: res.durationMs })),
      (err) => this.settle(gen, () => this.onState({ status: "error", error: (err as Error).message })),
    );
  }

  private settle(gen: number, apply: () => void): void {
    this.inFlight = false;
    if (gen === this.generation && !this.disposed) apply();  // drop stale
    if (this.pending && !this.disposed) {
      const next = this.pending;
      this.pending = null;
      this.start(next);
    }
  }

  dispose(): void {
    this.disposed = true;
    if (this.timer) clearTimeout(this.timer);
    this.pending = null;
  }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `npm run test -- preview-controller`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add src/lib/openscad/preview-controller.ts src/lib/openscad/preview-controller.test.ts
git commit -m "feat(preview): debounced, coalesced newest-wins preview controller"
```

---

### Task 5: STL viewer (react-three-fiber)

Parse binary STL → geometry (TDD'd pure function) and render it in an interactive r3f canvas. The WebGL view is browser-verified (Task 6); the parse is unit-tested.

**Files:**
- Create: `src/lib/stl/parse-stl.ts` (binary STL → positions Float32Array + triangle count)
- Test: `src/lib/stl/parse-stl.test.ts`
- Create: `src/components/StlViewer.tsx` (r3f Canvas, OrbitControls, grid, auto-fit, themed material)

**Interfaces:**
- Produces:
  - `interface StlMesh { positions: Float32Array; normals: Float32Array; triangleCount: number; bbox: { min: [number,number,number]; max: [number,number,number] } }`
  - `function parseBinaryStl(data: Uint8Array): StlMesh`
  - `function StlViewer(props: { stl?: Uint8Array; quality: "preview" | "final"; loading?: boolean }): JSX.Element`

- [ ] **Step 1: Write the failing test for STL parsing**

Create `src/lib/stl/parse-stl.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { parseBinaryStl } from "./parse-stl";

// Build a minimal binary STL: 80-byte header, uint32 triangle count, then per triangle
// 12 floats (normal + 3 verts) + uint16 attr. One triangle.
function makeOneTriangleStl(): Uint8Array {
  const triCount = 1;
  const buf = new ArrayBuffer(84 + triCount * 50);
  const dv = new DataView(buf);
  dv.setUint32(80, triCount, true);
  const floats = [0, 0, 1, /*n*/ 0, 0, 0, /*v1*/ 1, 0, 0, /*v2*/ 0, 1, 0 /*v3*/];
  let off = 84;
  for (const f of floats) { dv.setFloat32(off, f, true); off += 4; }
  // attr byte count uint16 left as 0
  return new Uint8Array(buf);
}

describe("parseBinaryStl", () => {
  it("parses triangle count, positions, and bounding box", () => {
    const mesh = parseBinaryStl(makeOneTriangleStl());
    expect(mesh.triangleCount).toBe(1);
    expect(mesh.positions.length).toBe(9); // 3 verts * 3 coords
    expect(Array.from(mesh.positions)).toEqual([0, 0, 0, 1, 0, 0, 0, 1, 0]);
    expect(mesh.bbox.min).toEqual([0, 0, 0]);
    expect(mesh.bbox.max).toEqual([1, 1, 0]);
  });

  it("throws on a too-short buffer", () => {
    expect(() => parseBinaryStl(new Uint8Array(10))).toThrow();
  });
});
```

- [ ] **Step 2: Run to verify failure**

Run: `npm run test -- parse-stl`
Expected: FAIL — not defined.

- [ ] **Step 3: Implement the STL parser**

Create `src/lib/stl/parse-stl.ts`:

```ts
export interface StlMesh {
  positions: Float32Array;
  normals: Float32Array;
  triangleCount: number;
  bbox: { min: [number, number, number]; max: [number, number, number] };
}

export function parseBinaryStl(data: Uint8Array): StlMesh {
  if (data.byteLength < 84) throw new Error("STL too short to contain a header");
  const dv = new DataView(data.buffer, data.byteOffset, data.byteLength);
  const triangleCount = dv.getUint32(80, true);
  const expected = 84 + triangleCount * 50;
  if (data.byteLength < expected) throw new Error(`STL truncated: expected ${expected} bytes`);

  const positions = new Float32Array(triangleCount * 9);
  const normals = new Float32Array(triangleCount * 9);
  const min: [number, number, number] = [Infinity, Infinity, Infinity];
  const max: [number, number, number] = [-Infinity, -Infinity, -Infinity];

  let off = 84;
  for (let t = 0; t < triangleCount; t++) {
    const nx = dv.getFloat32(off, true), ny = dv.getFloat32(off + 4, true), nz = dv.getFloat32(off + 8, true);
    off += 12;
    for (let v = 0; v < 3; v++) {
      const x = dv.getFloat32(off, true), y = dv.getFloat32(off + 4, true), z = dv.getFloat32(off + 8, true);
      off += 12;
      const i = t * 9 + v * 3;
      positions[i] = x; positions[i + 1] = y; positions[i + 2] = z;
      normals[i] = nx; normals[i + 1] = ny; normals[i + 2] = nz;
      if (x < min[0]) min[0] = x; if (y < min[1]) min[1] = y; if (z < min[2]) min[2] = z;
      if (x > max[0]) max[0] = x; if (y > max[1]) max[1] = y; if (z > max[2]) max[2] = z;
    }
    off += 2; // attribute byte count
  }
  return { positions, normals, triangleCount, bbox: { min, max } };
}
```

- [ ] **Step 4: Run to verify pass**

Run: `npm run test -- parse-stl`
Expected: PASS.

- [ ] **Step 5: Build the viewer component**

Create `src/components/StlViewer.tsx`. Uses r3f; builds a BufferGeometry from the parsed mesh; auto-fits the camera to the bbox; OrbitControls; a grid; themed material. Shows a loading overlay and a "preview quality" badge.

```tsx
"use client";
import { useMemo } from "react";
import { Canvas } from "@react-three/fiber";
import { OrbitControls, Grid, Bounds } from "@react-three/drei";
import * as THREE from "three";
import { parseBinaryStl } from "@/lib/stl/parse-stl";

function Model({ stl }: { stl: Uint8Array }) {
  const geometry = useMemo(() => {
    const mesh = parseBinaryStl(stl);
    const g = new THREE.BufferGeometry();
    g.setAttribute("position", new THREE.BufferAttribute(mesh.positions, 3));
    g.setAttribute("normal", new THREE.BufferAttribute(mesh.normals, 3));
    g.computeVertexNormals();
    return g;
  }, [stl]);
  return (
    <mesh geometry={geometry} castShadow>
      <meshStandardMaterial color={"#9a9a9a"} metalness={0.1} roughness={0.8} />
    </mesh>
  );
}

export function StlViewer({ stl, quality, loading }: {
  stl?: Uint8Array;
  quality: "preview" | "final";
  loading?: boolean;
}) {
  return (
    <div className="relative h-full w-full rounded-lg overflow-hidden"
      style={{ background: "var(--surface)", border: "1px solid var(--border)" }}>
      <Canvas camera={{ position: [80, 80, 80], fov: 45 }} shadows>
        <ambientLight intensity={0.6} />
        <directionalLight position={[50, 80, 30]} intensity={1.1} castShadow />
        <Grid args={[400, 400]} cellSize={10} sectionSize={50}
          cellColor={"#353535"} sectionColor={"#454545"} infiniteGrid fadeDistance={500}
          position={[0, -0.01, 0]} />
        {stl && (
          <Bounds fit clip observe margin={1.2}>
            {/* rotate so OpenSCAD's Z-up reads upright in three's Y-up */}
            <group rotation={[-Math.PI / 2, 0, 0]}>
              <Model stl={stl} />
            </group>
          </Bounds>
        )}
        <OrbitControls makeDefault enableDamping />
      </Canvas>

      {loading && (
        <div className="absolute inset-0 flex items-center justify-center text-sm"
          style={{ color: "var(--text-muted)", background: "rgba(0,0,0,0.35)" }}>
          rendering…
        </div>
      )}
      {quality === "preview" && stl && !loading && (
        <span className="absolute top-2 right-2 rounded px-2 py-0.5 text-xs"
          style={{ background: "var(--surface-muted)", color: "var(--text-dim)", border: "1px solid var(--border)" }}>
          preview quality
        </span>
      )}
    </div>
  );
}
```

- [ ] **Step 6: Run suite + build**

Run: `npm run test`
Expected: all pass (parse-stl + earlier).
Run: `npm run build`
Expected: compiles (r3f/three bundle OK).

- [ ] **Step 7: Commit**

```bash
git add src/lib/stl src/components/StlViewer.tsx
git commit -m "feat(viewer): binary STL parser and react-three-fiber STL viewer"
```

---

### Task 6: Assemble the customizer page (the integration gate)

Wire form + preview controller + viewer into the real page, replacing the Plan 1 render-core button. Auto-render preview on load and on every change (debounced); a full-quality "Download STL" bridge button. Browser-verified end-to-end.

**Files:**
- Modify: `src/app/page.tsx` (replace entirely)
- Reuse: `RenderClient`, `useCarrierForm`, `CarrierForm`, `PreviewController`, `StlViewer`.

**Interfaces:**
- Consumes everything produced in Tasks 1–5.

- [ ] **Step 1: Build the customizer page**

Replace `src/app/page.tsx`:

```tsx
"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { RenderClient } from "@/lib/openscad/client";
import { PreviewController, type PreviewState } from "@/lib/openscad/preview-controller";
import { useCarrierForm } from "@/hooks/use-carrier-form";
import { CarrierForm } from "@/components/CarrierForm";
import { StlViewer } from "@/components/StlViewer";

function newClient(): RenderClient {
  const worker = new Worker(new URL("../lib/openscad/worker.ts", import.meta.url), { type: "module" });
  return new RenderClient(worker);
}

export default function Home() {
  const { groups, values, setValue, toParams } = useCarrierForm();
  const [preview, setPreview] = useState<PreviewState>({ status: "idle" });
  const [downloading, setDownloading] = useState(false);
  const clientRef = useRef<RenderClient | null>(null);
  const ctlRef = useRef<PreviewController | null>(null);

  // Lazily create the worker client + preview controller (client-only).
  function controller(): PreviewController {
    if (!clientRef.current) clientRef.current = newClient();
    if (!ctlRef.current) {
      ctlRef.current = new PreviewController(clientRef.current, {
        debounceMs: 400,
        onState: setPreview,
      });
    }
    return ctlRef.current;
  }

  // Request a preview whenever params change (and once on mount).
  const params = useMemo(() => toParams({ Render_Quality: "preview" }), [toParams]);
  useEffect(() => {
    controller().request(params);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params]);

  useEffect(() => () => { ctlRef.current?.dispose(); clientRef.current?.dispose(); }, []);

  async function handleDownload() {
    setDownloading(true);
    try {
      const result = await (clientRef.current ?? (clientRef.current = newClient()))
        .render({ params: toParams({ Render_Quality: "final" }), quality: "final" });
      const blob = new Blob([new Uint8Array(result.stl)], { type: "model/stl" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      const ct = String(values.Carrier_Type), ff = String(values.Film_Format);
      const part = String(values.Top_or_Bottom);
      a.href = url;
      a.download = `${ct}_${ff}_${part}.stl`.replace(/\s+/g, "-");
      a.click();
      URL.revokeObjectURL(url);
    } finally {
      setDownloading(false);
    }
  }

  return (
    <main className="min-h-screen p-4 md:p-8">
      <header className="mb-6">
        <h1 className="text-3xl font-semibold">DarkroomSCAD</h1>
        <p style={{ color: "var(--text-muted)" }}>Configure your negative carrier and download a print-ready STL.</p>
      </header>

      <div className="grid gap-6 md:grid-cols-[minmax(320px,420px)_1fr]">
        <div>
          <CarrierForm groups={groups} values={values} setValue={setValue} />
          <button onClick={handleDownload} disabled={downloading || preview.status === "error"}
            className="mt-6 w-full rounded px-4 py-2.5 font-medium"
            style={{ background: "var(--primary)", color: "#08120b", opacity: downloading ? 0.6 : 1 }}>
            {downloading ? "Rendering STL…" : "Download STL (full quality)"}
          </button>
          {preview.status === "error" && (
            <p className="mt-2 text-sm" style={{ color: "var(--error)" }}>Render error: {preview.error}</p>
          )}
        </div>

        <div className="h-[60vh] md:h-[calc(100vh-8rem)] sticky top-8">
          <StlViewer stl={preview.stl} quality="preview" loading={preview.status === "rendering"} />
        </div>
      </div>
    </main>
  );
}
```

- [ ] **Step 2: Lint/build check**

Run: `npx tsc --noEmit` → clean.
Run: `npm run build` → compiles successfully.
(If ESLint flags the intentional `exhaustive-deps` disable or worker `any`, the Plan 1 `eslint.config.mjs` override already covers WASM-interop/test files; add a narrow disable only where the brief shows one.)

- [ ] **Step 3: Manual browser verification (the gate — controller runs this)**

Run: `npm run dev`. Load the page.
Expected:
1. The form renders grouped controls (Carrier / Text / Options) on the left; the 3D viewer on the right shows the default Omega-D 35mm bottom carrier after the first preview (~few seconds), with a "preview quality" badge.
2. Changing **Film format** to `6x6` re-renders the preview (debounced) and the model updates.
3. Toggling **Etch a name** off hides the Name field; setting **Film format** to `custom` reveals the four custom-dimension fields.
4. Orbit/zoom works in the viewer.
5. "Download STL (full quality)" downloads a named `.stl`.
Capture a screenshot of the working customizer.

- [ ] **Step 4: Commit**

```bash
git add src/app/page.tsx
git commit -m "feat: assemble guided customizer page — form + live preview + viewer + download"
```

- [ ] **Step 5: Push**

```bash
git push origin main
```

---

## Plan 2 Self-Review

- **Spec coverage (Plan 2 portion of the design spec):** curation overlay + labels/grouping/advanced/fonts/conditional-visibility (Tasks 2–3) ✓; build-time schema↔overlay consistency check (Task 2 Step 7) ✓; form from schema+overlay with conditional visibility (Task 3) ✓; debounced preview + newest-wins cancellation (Task 4) ✓; react-three-fiber viewer with orbit/zoom/grid/auto-fit/themed materials + "preview quality" badge (Task 5) ✓; `Render_Quality` system-managed preview-vs-final (Global Constraints + Tasks 4/6) ✓; Lucida Console → bundled-font remap (Task 2 `SYSTEM_DEFAULT_OVERRIDES`) ✓; baseline dorkroom dark styling + Fraunces/Montserrat (Task 1) ✓. Deferred to Plan 3 by design: ZIP/part-enumeration export, full theme system, comprehensive error UX, Vercel deploy.
- **Placeholder scan:** none — every code step has complete code; the one deferred area (full export/theme) is explicitly scoped out, not hand-waved.
- **Type consistency:** `FormValue`/`ResolvedField`/`ResolvedGroup`/`GroupConfig`/`FieldConfig` defined in `src/lib/form/types.ts` (Task 2) and consumed unchanged in Tasks 3/6. `resolveFormModel`/`validateOverlay` signatures consistent (Tasks 2,3,6). `PreviewController`/`PreviewState` (Task 4) consumed in Task 6. `parseBinaryStl`/`StlMesh` (Task 5) consumed by `StlViewer`. `toRenderParams(groups, values, system)` consistent (Tasks 3,6). Reuses Plan 1 `RenderClient.render(req)`/`RenderParams`/`RenderResult` unchanged.

## Notes for the executor

- **Manifold speed:** first preview includes WASM instantiation + asset fetch (~3–5s); subsequent previews are faster. The debounce (400ms) + coalescing keeps the UI responsive without queueing renders.
- **No true mid-render cancel:** `callMain` cannot be interrupted; the controller drops stale results and coalesces to the latest pending request. That's the intended "newest-wins" behavior — do not attempt to terminate/respawn the worker per keystroke.
- **Z-up vs Y-up:** OpenSCAD STLs are Z-up; the viewer rotates the model -90° on X so it reads upright. If the model looks laid on its side, that rotation is the knob.
