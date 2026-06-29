# DarkroomSCAD Web — Plan 1: Foundation & Render Core

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `darkroomscad-web` repo and a working client-side slice that renders the default DarkroomSCAD carrier to an STL in the browser via WASM and downloads it — proving `textmetrics`, BOSL2, and fonts work end-to-end.

**Architecture:** Next.js (App Router) static app on Vercel. A build-time script syncs `.scad` source from the DarkroomSCAD repo and parses its customizer annotations into a JSON schema. OpenSCAD runs entirely in the browser inside a Web Worker (`openscad-wasm`, Manifold backend), with BOSL2 + bundled fonts mounted into its virtual filesystem. Plan 1 stops at a single hard-coded render-and-download path; the guided UI (Plan 2) and export/theming (Plan 3) build on this core.

**Tech Stack:** Next.js 15 (App Router) + TypeScript, Tailwind CSS, `openscad-wasm`, BOSL2, Vitest (unit + node integration), `fflate` (later plans).

## Global Constraints

- **This is a NEW, SEPARATE repo.** All tasks operate in `~/workspace/darkroomscad-web` (created in Task 1), NOT in `DarkroomSCAD`. The DarkroomSCAD repo is read-only source pulled via the sync script.
- **No backend / no serverless rendering.** All OpenSCAD execution is client-side WASM in a Web Worker. The deployed app must be effectively static.
- **Manifold backend** for all renders (`--backend=manifold`).
- **`textmetrics` is load-bearing** — the carrier's text centering uses it. The chosen `openscad-wasm` release MUST have it enabled. Validating this is the explicit purpose of Task 5.
- **Pinned versions:** `openscad-wasm` release, BOSL2 version, and the DarkroomSCAD source ref are all pinned (no floating `latest`/`main` at build time). Defaults: DarkroomSCAD ref = current `main` SHA; record exact SHAs in `package.json`/config when set.
- **Proprietary fonts cannot ship.** The DarkroomSCAD default `Fontface = "Lucida Console"` must be remapped to a bundled open font.
- **Source of truth for design:** `docs/superpowers/specs/2026-06-29-darkroomscad-web-design.md` in the DarkroomSCAD repo.

---

### Task 1: Repo scaffold

**Files:**
- Create: `~/workspace/darkroomscad-web/` (Next.js app via `create-next-app`)
- Create: `~/workspace/darkroomscad-web/.nvmrc`
- Create: `~/workspace/darkroomscad-web/README.md`
- Modify: `~/workspace/darkroomscad-web/next.config.ts` (WASM-friendly headers)

**Interfaces:**
- Produces: a runnable Next.js app at `~/workspace/darkroomscad-web` with Tailwind, TypeScript, Vitest, and the directory skeleton later tasks write into.

- [ ] **Step 1: Scaffold the Next.js app**

```bash
cd ~/workspace
npx create-next-app@15 darkroomscad-web \
  --typescript --tailwind --eslint --app --src-dir --use-npm \
  --import-alias "@/*" --no-turbopack
cd darkroomscad-web
```

- [ ] **Step 2: Add dev/test dependencies and create the directory skeleton**

```bash
npm install -D vitest @vitejs/plugin-react jsdom @testing-library/react
mkdir -p scripts src/lib/openscad src/lib/params src/config public/scad public/wasm public/libraries public/fonts generated
node --version > .nvmrc
```

- [ ] **Step 3: Configure cross-origin isolation headers (required by some WASM/threads builds)**

Replace `next.config.ts` with:

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
          { key: "Cross-Origin-Embedder-Policy", value: "require-corp" },
        ],
      },
    ];
  },
};

export default nextConfig;
```

- [ ] **Step 4: Add Vitest config**

Create `vitest.config.ts`:

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["src/**/*.test.ts", "scripts/**/*.test.ts"],
  },
});
```

Add to `package.json` scripts: `"test": "vitest run"`, `"test:watch": "vitest"`.

- [ ] **Step 5: Verify the app builds and runs**

Run: `npm run build`
Expected: build completes with no errors.
Run: `npm run test`
Expected: "No test files found" (exit 0) — confirms Vitest is wired.

- [ ] **Step 6: Initialize git and commit**

```bash
git init
git add -A
git commit -m "chore: scaffold darkroomscad-web (Next.js + Tailwind + Vitest)"
```

---

### Task 2: Customizer annotation parser

This is the heart of the param system and is pure logic — full TDD. It parses OpenSCAD
customizer syntax into a typed schema that Plan 2's UI consumes.

**Files:**
- Create: `src/lib/params/types.ts`
- Create: `src/lib/params/parse-customizer.ts`
- Test: `src/lib/params/parse-customizer.test.ts`

**Interfaces:**
- Produces:
  - `type ParamType = "string" | "number" | "boolean" | "enum"`
  - `interface ParamOption { value: string | number; label: string }`
  - `interface Param { name: string; section: string; type: ParamType; default: string | number | boolean; options?: ParamOption[]; min?: number; max?: number; step?: number; description?: string; hidden: boolean }`
  - `interface ParamSchema { params: Param[] }`
  - `function parseCustomizer(scad: string): ParamSchema`

- [ ] **Step 1: Write the types**

Create `src/lib/params/types.ts`:

```ts
export type ParamType = "string" | "number" | "boolean" | "enum";

export interface ParamOption {
  value: string | number;
  label: string;
}

export interface Param {
  name: string;
  section: string;
  type: ParamType;
  default: string | number | boolean;
  options?: ParamOption[];
  min?: number;
  max?: number;
  step?: number;
  description?: string;
  hidden: boolean;
}

export interface ParamSchema {
  params: Param[];
}
```

- [ ] **Step 2: Write the failing tests**

Create `src/lib/params/parse-customizer.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { parseCustomizer } from "./parse-customizer";

describe("parseCustomizer", () => {
  it("parses a string dropdown with section and description", () => {
    const scad = [
      "/* [Carrier Type] */",
      "Orientation = \"vertical\"; // [\"vertical\", \"horizontal\"]",
    ].join("\n");
    const { params } = parseCustomizer(scad);
    expect(params).toHaveLength(1);
    expect(params[0]).toMatchObject({
      name: "Orientation",
      section: "Carrier Type",
      type: "enum",
      default: "vertical",
      hidden: false,
      options: [
        { value: "vertical", label: "vertical" },
        { value: "horizontal", label: "horizontal" },
      ],
    });
  });

  it("captures the preceding comment as description", () => {
    const scad = [
      "/* [Customization] */",
      "// Name to etch on the carrier",
      "Owner_Name = \"NAME\";",
    ].join("\n");
    const { params } = parseCustomizer(scad);
    expect(params[0].description).toBe("Name to etch on the carrier");
    expect(params[0].type).toBe("string");
    expect(params[0].default).toBe("NAME");
  });

  it("parses a boolean value", () => {
    const scad = "Alignment_Board = true; // [true, false]";
    const { params } = parseCustomizer(scad);
    expect(params[0]).toMatchObject({ type: "boolean", default: true });
  });

  it("parses a numeric range annotation", () => {
    const scad = "Font_Size = 10; // [6:0.5:40]";
    const { params } = parseCustomizer(scad);
    expect(params[0]).toMatchObject({
      type: "number",
      default: 10,
      min: 6,
      step: 0.5,
      max: 40,
    });
  });

  it("parses a bare numeric value with no annotation", () => {
    const scad = "Custom_Film_Width = 37;";
    const { params } = parseCustomizer(scad);
    expect(params[0]).toMatchObject({ type: "number", default: 37 });
  });

  it("marks params under /* [Hidden] */ as hidden", () => {
    const scad = [
      "/* [Hidden] */",
      "$fn = 100;",
    ].join("\n");
    const { params } = parseCustomizer(scad);
    expect(params[0].hidden).toBe(true);
  });

  it("ignores include/use lines and non-assignment code", () => {
    const scad = [
      "include <BOSL2/std.scad>",
      "module foo() { cube(1); }",
      "Owner_Name = \"NAME\";",
    ].join("\n");
    const { params } = parseCustomizer(scad);
    expect(params.map((p) => p.name)).toEqual(["Owner_Name"]);
  });
});
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `npm run test -- parse-customizer`
Expected: FAIL — `parseCustomizer` is not defined.

- [ ] **Step 4: Implement the parser**

Create `src/lib/params/parse-customizer.ts`:

```ts
import type { Param, ParamOption, ParamSchema, ParamType } from "./types";

const SECTION_RE = /^\s*\/\*\s*\[(.+?)\]\s*\*\/\s*$/;
const LINE_COMMENT_RE = /^\s*\/\/\s?(.*)$/;
const ASSIGN_RE = /^\s*([A-Za-z_$][A-Za-z0-9_$]*)\s*=\s*(.+?);\s*(?:\/\/\s*(.*))?$/;

function parseLiteral(raw: string): { type: ParamType; value: string | number | boolean } {
  const t = raw.trim();
  if (t === "true" || t === "false") return { type: "boolean", value: t === "true" };
  if (/^".*"$/.test(t)) return { type: "string", value: t.slice(1, -1) };
  const n = Number(t);
  if (!Number.isNaN(n) && t !== "") return { type: "number", value: n };
  // Fallback: treat as string (e.g. an expression default we won't expose)
  return { type: "string", value: t };
}

function parseOptions(annotation: string): ParamOption[] | null {
  const m = annotation.match(/^\[(.*)\]$/);
  if (!m) return null;
  const inner = m[1].trim();
  if (inner === "") return null;
  // Range form: [min:max] or [min:step:max] — handled by caller, not here.
  if (/^-?\d*\.?\d+(\s*:\s*-?\d*\.?\d+){1,2}$/.test(inner)) return null;
  const parts = splitTopLevel(inner);
  return parts.map((p) => {
    const labelMatch = p.match(/^(.*?):(.*)$/);
    const rawVal = (labelMatch ? labelMatch[1] : p).trim();
    const lit = parseLiteral(rawVal);
    const value = lit.type === "number" ? (lit.value as number) : String(lit.value);
    const label = labelMatch ? labelMatch[2].trim() : String(value);
    return { value, label };
  });
}

function parseRange(annotation: string): { min: number; step?: number; max: number } | null {
  const m = annotation.match(/^\[\s*(-?\d*\.?\d+)\s*:\s*(-?\d*\.?\d+)\s*(?::\s*(-?\d*\.?\d+)\s*)?\]$/);
  if (!m) return null;
  if (m[3] !== undefined) return { min: Number(m[1]), step: Number(m[2]), max: Number(m[3]) };
  return { min: Number(m[1]), max: Number(m[2]) };
}

// Split a comma-separated list ignoring commas inside quotes.
function splitTopLevel(s: string): string[] {
  const out: string[] = [];
  let cur = "";
  let inStr = false;
  for (const ch of s) {
    if (ch === '"') inStr = !inStr;
    if (ch === "," && !inStr) {
      out.push(cur);
      cur = "";
    } else {
      cur += ch;
    }
  }
  if (cur.trim() !== "") out.push(cur);
  return out;
}

export function parseCustomizer(scad: string): ParamSchema {
  const lines = scad.split("\n");
  const params: Param[] = [];
  let section = "";
  let hidden = false;
  let pendingDescription: string | undefined;

  for (const line of lines) {
    const sectionMatch = line.match(SECTION_RE);
    if (sectionMatch) {
      section = sectionMatch[1].trim();
      hidden = section.toLowerCase() === "hidden";
      pendingDescription = undefined;
      continue;
    }

    const assign = line.match(ASSIGN_RE);
    if (assign) {
      const [, name, rawValue, annotation] = assign;
      const lit = parseLiteral(rawValue);
      const param: Param = {
        name,
        section,
        type: lit.type,
        default: lit.value,
        hidden,
        description: pendingDescription,
      };
      if (annotation) {
        const ann = annotation.trim();
        const range = parseRange(ann);
        if (range) {
          param.type = "number";
          param.min = range.min;
          param.max = range.max;
          if (range.step !== undefined) param.step = range.step;
        } else {
          const options = parseOptions(ann);
          if (options) {
            const isBool =
              options.length === 2 &&
              options.every((o) => o.value === true || o.value === false || o.label === "true" || o.label === "false");
            if (!isBool && lit.type !== "boolean") {
              param.type = "enum";
              param.options = options;
            }
          }
        }
      }
      params.push(param);
      pendingDescription = undefined;
      continue;
    }

    const comment = line.match(LINE_COMMENT_RE);
    if (comment) {
      pendingDescription = comment[1].trim() || undefined;
      continue;
    }

    // Any other line (include/use/module/blank) clears a dangling description.
    if (line.trim() !== "") pendingDescription = undefined;
  }

  return { params };
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `npm run test -- parse-customizer`
Expected: PASS (7 tests).

- [ ] **Step 6: Commit**

```bash
git add src/lib/params
git commit -m "feat: customizer annotation parser with typed schema"
```

---

### Task 3: SCAD source sync script

Pulls the carrier source from DarkroomSCAD and emits both the SCAD tree (for the WASM FS)
and the generated parameter schema.

**Files:**
- Create: `scripts/sync-scad.ts`
- Test: `scripts/sync-scad.test.ts`
- Modify: `package.json` (add `sync:scad` and `prebuild` scripts)

**Interfaces:**
- Consumes: `parseCustomizer` from `src/lib/params/parse-customizer.ts`.
- Produces:
  - Files under `public/scad/**` (mirrors `carrier.scad` + `src/**` from DarkroomSCAD).
  - `generated/param-schema.json` (a serialized `ParamSchema`).
  - `function collectScadFiles(rootDir: string): string[]` (exported, testable).

- [ ] **Step 1: Write the failing test for file collection**

Create `scripts/sync-scad.test.ts`:

```ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { mkdtempSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { collectScadFiles } from "./sync-scad";

let dir: string;

beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "scad-"));
  mkdirSync(join(dir, "src", "common"), { recursive: true });
  writeFileSync(join(dir, "carrier.scad"), "// main");
  writeFileSync(join(dir, "src", "carrier-configs.scad"), "// cfg");
  writeFileSync(join(dir, "src", "common", "film-sizes.scad"), "// films");
  writeFileSync(join(dir, "src", "notes.txt"), "ignore me");
});

afterAll(() => rmSync(dir, { recursive: true, force: true }));

describe("collectScadFiles", () => {
  it("returns all .scad files recursively, relative to root", () => {
    const files = collectScadFiles(dir).sort();
    expect(files).toEqual([
      "carrier.scad",
      "src/carrier-configs.scad",
      "src/common/film-sizes.scad",
    ]);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test -- sync-scad`
Expected: FAIL — `collectScadFiles` is not defined.

- [ ] **Step 3: Implement the sync script**

Create `scripts/sync-scad.ts`:

```ts
import {
  readdirSync,
  statSync,
  mkdirSync,
  copyFileSync,
  writeFileSync,
  readFileSync,
  rmSync,
  existsSync,
} from "node:fs";
import { join, relative, dirname } from "node:path";
import { parseCustomizer } from "../src/lib/params/parse-customizer";

const CARRIER_ROOT_SUBDIR = "negative-carriers"; // location of carrier.scad within DarkroomSCAD

export function collectScadFiles(rootDir: string): string[] {
  const out: string[] = [];
  function walk(dir: string) {
    for (const entry of readdirSync(dir)) {
      const full = join(dir, entry);
      if (statSync(full).isDirectory()) walk(full);
      else if (entry.endsWith(".scad")) out.push(relative(rootDir, full));
    }
  }
  walk(rootDir);
  return out;
}

function resolveSource(): string {
  // --local <path> overrides the default; otherwise expect a prepared checkout.
  const localFlag = process.argv.indexOf("--local");
  const base =
    localFlag !== -1
      ? process.argv[localFlag + 1]
      : process.env.DARKROOMSCAD_PATH ?? "../DarkroomSCAD";
  const root = join(base, CARRIER_ROOT_SUBDIR);
  if (!existsSync(join(root, "carrier.scad"))) {
    throw new Error(`carrier.scad not found under ${root}. Pass --local <DarkroomSCAD path>.`);
  }
  return root;
}

function main() {
  const sourceRoot = resolveSource();
  const destScad = join(process.cwd(), "public", "scad");
  rmSync(destScad, { recursive: true, force: true });
  mkdirSync(destScad, { recursive: true });

  const files = collectScadFiles(sourceRoot);
  for (const rel of files) {
    const dest = join(destScad, rel);
    mkdirSync(dirname(dest), { recursive: true });
    copyFileSync(join(sourceRoot, rel), dest);
  }

  const carrierSource = readFileSync(join(sourceRoot, "carrier.scad"), "utf8");
  const schema = parseCustomizer(carrierSource);
  const generatedDir = join(process.cwd(), "generated");
  mkdirSync(generatedDir, { recursive: true });
  writeFileSync(join(generatedDir, "param-schema.json"), JSON.stringify(schema, null, 2));

  console.log(`Synced ${files.length} .scad files; ${schema.params.length} params parsed.`);
}

// Only run when invoked directly (not when imported by tests).
if (process.argv[1] && process.argv[1].endsWith("sync-scad.ts")) main();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test -- sync-scad`
Expected: PASS.

- [ ] **Step 5: Wire up package scripts and run a real sync**

Add to `package.json` scripts:
```json
"sync:scad": "tsx scripts/sync-scad.ts",
"prebuild": "tsx scripts/sync-scad.ts"
```
Install the runner: `npm install -D tsx`

Run: `npm run sync:scad -- --local ../DarkroomSCAD`
Expected: console reports files synced and params parsed; `public/scad/carrier.scad`, `public/scad/src/common/film-sizes.scad`, and `generated/param-schema.json` exist.

- [ ] **Step 6: Inspect the generated schema sanity-check**

Run: `node -e "const s=require('./generated/param-schema.json'); console.log(s.params.find(p=>p.name==='Film_Format'))"`
Expected: prints the `Film_Format` param with `type: "enum"` and an `options` array including `35mm`, `6x6`, `4x5`, `custom`.

- [ ] **Step 7: Commit**

```bash
git add scripts/sync-scad.ts scripts/sync-scad.test.ts package.json package-lock.json public/scad generated/param-schema.json
git commit -m "feat: sync DarkroomSCAD source and generate param schema"
```

---

### Task 4: Vendor the WASM engine, BOSL2, and fonts

Static assets the worker mounts. No tests (pure asset vendoring); the deliverable is verified
by Task 5's render.

**Files:**
- Create: `public/wasm/openscad.js`, `public/wasm/openscad.wasm` (+ any `.data`/`.wasm.js` glue from the release)
- Create: `public/libraries/BOSL2/**`
- Create: `public/fonts/LiberationMono-Regular.ttf` (+ a small fonts manifest)
- Create: `src/config/fonts.ts`
- Create: `VENDORING.md` (records exact pinned versions/URLs)

**Interfaces:**
- Produces:
  - `BUNDLED_FONTS: { id: string; family: string; file: string }[]` from `src/config/fonts.ts`
  - `DEFAULT_FONT_FAMILY: string` (the remap target for `Lucida Console`)

- [ ] **Step 1: Download a pinned `openscad-wasm` release**

Fetch the latest `openscad-wasm` release that tracks an OpenSCAD nightly with Manifold + textmetrics (check https://github.com/openscad/openscad-wasm/releases). Extract `openscad.js`, `openscad.wasm`, and any accompanying glue into `public/wasm/`. Record the exact release tag and asset URLs in `VENDORING.md`.

- [ ] **Step 2: Vendor a pinned BOSL2**

Clone BOSL2 at a pinned tag and copy its contents so the include path `BOSL2/std.scad` resolves:

```bash
git clone --depth 1 --branch v2.0.716 https://github.com/BelfrySCAD/BOSL2 /tmp/bosl2
mkdir -p public/libraries/BOSL2
cp /tmp/bosl2/*.scad public/libraries/BOSL2/
```
(Use the BOSL2 tag current at implementation time; record it in `VENDORING.md`.)

- [ ] **Step 3: Vendor an open mono font and define the font config**

Download Liberation Mono (SIL OFL) to `public/fonts/LiberationMono-Regular.ttf`. Create `src/config/fonts.ts`:

```ts
export interface BundledFont {
  id: string;
  family: string;
  file: string;
}

export const BUNDLED_FONTS: BundledFont[] = [
  { id: "liberation-mono", family: "Liberation Mono", file: "LiberationMono-Regular.ttf" },
];

// DarkroomSCAD ships Lucida Console (proprietary); remap to a bundled face.
export const DEFAULT_FONT_FAMILY = "Liberation Mono";
```

- [ ] **Step 4: Verify assets are present**

Run: `ls -la public/wasm public/libraries/BOSL2 public/fonts | head -40`
Expected: `openscad.js` + `openscad.wasm` present; `BOSL2/std.scad` present; `LiberationMono-Regular.ttf` present.

- [ ] **Step 5: Commit**

```bash
git add public/wasm public/libraries public/fonts src/config/fonts.ts VENDORING.md
git commit -m "chore: vendor pinned openscad-wasm, BOSL2, and open fonts"
```

---

### Task 5: WASM render core + textmetrics spike (THE RISK GATE)

The make-or-break task. A Web Worker that mounts the FS and renders the default carrier.
A Node integration test proves the same render pipeline works headlessly — including
`textmetrics` and BOSL2 — before any UI is built.

**Files:**
- Create: `src/lib/openscad/render.ts` (environment-agnostic render core)
- Create: `src/lib/openscad/params.ts` (param-set JSON builder)
- Create: `src/lib/openscad/worker.ts` (Web Worker entry; thin wrapper over render core)
- Create: `src/lib/openscad/types.ts`
- Test: `src/lib/openscad/params.test.ts`
- Test: `src/lib/openscad/render.integration.test.ts`

**Interfaces:**
- Consumes: vendored assets from Task 4; synced SCAD from Task 3.
- Produces:
  - `interface RenderParams { [name: string]: string | number | boolean }`
  - `interface RenderRequest { params: RenderParams; quality: "preview" | "final"; mainFile?: string }`
  - `interface RenderResult { stl: Uint8Array; log: string; durationMs: number }`
  - `function buildParamSetJson(params: RenderParams, setName: string): string`
  - `async function renderScad(loadModule, fsAssets, req: RenderRequest): Promise<RenderResult>`
  - Worker message protocol: post `{ type: "render", id, req }` → receive `{ type: "result", id, result }` or `{ type: "error", id, message }`.

- [ ] **Step 1: Write the failing test for the param-set builder**

Create `src/lib/openscad/params.test.ts`:

```ts
import { describe, it, expect } from "vitest";
import { buildParamSetJson } from "./params";

describe("buildParamSetJson", () => {
  it("serializes a customizer parameter set OpenSCAD can read", () => {
    const json = buildParamSetJson(
      { Owner_Name: "AARON", Film_Format: "35mm", Alignment_Board: true, Font_Size: 10 },
      "web",
    );
    const parsed = JSON.parse(json);
    expect(parsed.fileFormatVersion).toBe("1");
    // OpenSCAD parameter sets store every value as a string.
    expect(parsed.parameterSets.web).toEqual({
      Owner_Name: "AARON",
      Film_Format: "35mm",
      Alignment_Board: "true",
      Font_Size: "10",
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test -- params`
Expected: FAIL — `buildParamSetJson` is not defined.

- [ ] **Step 3: Implement types and the param-set builder**

Create `src/lib/openscad/types.ts`:

```ts
export type RenderQuality = "preview" | "final";

export interface RenderParams {
  [name: string]: string | number | boolean;
}

export interface RenderRequest {
  params: RenderParams;
  quality: RenderQuality;
  mainFile?: string; // default "carrier.scad"
}

export interface RenderResult {
  stl: Uint8Array;
  log: string;
  durationMs: number;
}
```

Create `src/lib/openscad/params.ts`:

```ts
import type { RenderParams } from "./types";

export function buildParamSetJson(params: RenderParams, setName: string): string {
  const stringified: Record<string, string> = {};
  for (const [key, value] of Object.entries(params)) {
    stringified[key] = typeof value === "string" ? value : String(value);
  }
  return JSON.stringify({
    fileFormatVersion: "1",
    parameterSets: { [setName]: stringified },
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test -- params`
Expected: PASS.

- [ ] **Step 5: Implement the environment-agnostic render core**

Create `src/lib/openscad/render.ts`. `loadModule` and `fsAssets` are injected so the same
core runs in both the browser worker and the Node integration test.

```ts
import { buildParamSetJson } from "./params";
import type { RenderRequest, RenderResult } from "./types";

// A single virtual-FS file to mount before rendering.
export interface FsFile {
  path: string; // absolute path in the WASM FS, e.g. "/scad/carrier.scad"
  data: Uint8Array;
}

export interface FsAssets {
  files: FsFile[];
  // Directory on the OpenSCAD library search path (BOSL2 lives here).
  libraryDir: string; // e.g. "/libraries"
  // Directory containing fonts + fontconfig.
  fontDir: string; // e.g. "/fonts"
}

// loadModule resolves an initialized emscripten OpenSCAD module
// ({ FS, callMain, ENV } with noInitialRun: true).
export type LoadModule = () => Promise<any>;

const SET_NAME = "web";

export async function renderScad(
  loadModule: LoadModule,
  fsAssets: FsAssets,
  req: RenderRequest,
): Promise<RenderResult> {
  const instance = await loadModule();
  const log: string[] = [];

  // Mount all asset files.
  for (const file of fsAssets.files) {
    const dir = file.path.slice(0, file.path.lastIndexOf("/"));
    if (dir) {
      try {
        instance.FS.mkdirTree(dir);
      } catch {
        /* already exists */
      }
    }
    instance.FS.writeFile(file.path, file.data);
  }

  // Library search path so `include <BOSL2/std.scad>` resolves.
  instance.ENV = instance.ENV ?? {};
  instance.ENV.OPENSCADPATH = fsAssets.libraryDir;

  // Customizer parameter set.
  const paramJson = buildParamSetJson(req.params, SET_NAME);
  instance.FS.writeFile("/params.json", paramJson);

  const mainFile = req.mainFile ?? "carrier.scad";
  const mainPath = `/scad/${mainFile}`;
  const outPath = "/out.stl";

  const args = [
    mainPath,
    "-o",
    outPath,
    "--export-format=binstl",
    "--backend=manifold",
    "-p",
    "/params.json",
    "-P",
    SET_NAME,
  ];

  const start = performance.now();
  const code = instance.callMain(args);
  const durationMs = performance.now() - start;

  if (code !== 0 && code !== undefined && code !== null) {
    throw new Error(`OpenSCAD exited with code ${code}. ${log.join("\n")}`);
  }

  let stl: Uint8Array;
  try {
    stl = instance.FS.readFile(outPath);
  } catch {
    throw new Error(`Render produced no output. ${log.join("\n")}`);
  }
  if (stl.byteLength === 0) {
    throw new Error("Render produced an empty (degenerate) STL.");
  }

  return { stl, log: log.join("\n"), durationMs };
}
```

- [ ] **Step 6: Write the headless integration test (the spike)**

Create `src/lib/openscad/render.integration.test.ts`. This loads the real vendored WASM in
Node, renders the default carrier with a bundled font, and asserts a valid binary STL. It is
the proof that `textmetrics` + BOSL2 + fonts work.

```ts
import { describe, it, expect } from "vitest";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, relative } from "node:path";
import { renderScad, type FsAssets, type FsFile } from "./render";
import { DEFAULT_FONT_FAMILY } from "../../config/fonts";

const WASM_JS = join(process.cwd(), "public/wasm/openscad.js");
const hasWasm = existsSync(WASM_JS);

function readDirRecursive(dir: string, prefix: string): FsFile[] {
  const out: FsFile[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) out.push(...readDirRecursive(full, prefix));
    else {
      const rel = relative(join(process.cwd(), prefix), full).split("\\").join("/");
      out.push({ path: `/${prefix}/${rel}`, data: new Uint8Array(readFileSync(full)) });
    }
  }
  return out;
}

describe.runIf(hasWasm)("renderScad (integration)", () => {
  it("renders the default carrier to a non-empty binary STL", async () => {
    // Dynamic import of the emscripten factory (CommonJS/ESM interop varies by build).
    const mod = await import(WASM_JS);
    const factory = (mod.default ?? mod) as (opts: object) => Promise<any>;
    const loadModule = () => factory({ noInitialRun: true });

    const scadFiles = readDirRecursive(join(process.cwd(), "public/scad"), "scad");
    const fontFiles = readDirRecursive(join(process.cwd(), "public/fonts"), "fonts");
    const libFiles = readDirRecursive(join(process.cwd(), "public/libraries"), "libraries");

    const fsAssets: FsAssets = {
      files: [...scadFiles, ...fontFiles, ...libFiles],
      libraryDir: "/libraries",
      fontDir: "/fonts",
    };

    const result = await renderScad(loadModule, fsAssets, {
      params: {
        Carrier_Type: "omega-d",
        Film_Format: "35mm",
        Orientation: "vertical",
        Top_or_Bottom: "bottom",
        Render_Quality: "preview",
        Owner_Name: "TEST",
        Fontface: DEFAULT_FONT_FAMILY,
      },
      quality: "preview",
    });

    expect(result.stl.byteLength).toBeGreaterThan(84); // STL header is 84 bytes
    // Binary STL: triangle count at bytes 80-84 must be > 0.
    const view = new DataView(result.stl.buffer, result.stl.byteOffset);
    expect(view.getUint32(80, true)).toBeGreaterThan(0);
  }, 120_000);
});
```

- [ ] **Step 7: Run the integration test (the gate)**

Run: `npm run test -- render.integration`
Expected: PASS — a non-empty STL with > 0 triangles.

**If it FAILS specifically on text/font/`textmetrics`:** this is Open Risk #1 firing. STOP and report. The fallback (per the spec) is a JS `textmetrics` shim that computes centering offsets and passes them as params; that becomes a new task before proceeding. Do not paper over it.

**If it FAILS on BOSL2 includes:** the library path mounting (`OPENSCADPATH`) needs adjusting — consult the openscad-playground source for the exact mount convention and fix `render.ts` Step 5. Re-run until green.

- [ ] **Step 8: Implement the Web Worker wrapper**

Create `src/lib/openscad/worker.ts`:

```ts
/// <reference lib="webworker" />
import { renderScad, type FsAssets } from "./render";
import type { RenderRequest, RenderResult } from "./types";

declare const self: DedicatedWorkerGlobalScope;

let assetsPromise: Promise<FsAssets> | null = null;
let loadModulePromise: Promise<any> | null = null;

async function fetchBytes(url: string): Promise<Uint8Array> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Failed to fetch ${url}: ${res.status}`);
  return new Uint8Array(await res.arrayBuffer());
}

// Manifest of asset URLs is generated at build time (Task in Plan 2); for Plan 1
// the worker fetches a static manifest committed alongside it.
async function loadAssets(): Promise<FsAssets> {
  const manifest = await (await fetch("/scad-manifest.json")).json();
  const files = await Promise.all(
    manifest.files.map(async (f: { url: string; path: string }) => ({
      path: f.path,
      data: await fetchBytes(f.url),
    })),
  );
  return { files, libraryDir: "/libraries", fontDir: "/fonts" };
}

function loadModule() {
  if (!loadModulePromise) {
    loadModulePromise = import(/* @vite-ignore */ "/wasm/openscad.js").then((m) =>
      (m.default ?? m)({ noInitialRun: true }),
    );
  }
  return loadModulePromise;
}

self.onmessage = async (e: MessageEvent) => {
  const { type, id, req } = e.data as { type: string; id: number; req: RenderRequest };
  if (type !== "render") return;
  try {
    if (!assetsPromise) assetsPromise = loadAssets();
    const assets = await assetsPromise;
    const result: RenderResult = await renderScad(loadModule, assets, req);
    self.postMessage({ type: "result", id, result }, [result.stl.buffer]);
  } catch (err) {
    self.postMessage({ type: "error", id, message: (err as Error).message });
  }
};
```

- [ ] **Step 9: Generate the asset manifest the worker fetches**

Extend `scripts/sync-scad.ts`'s `main()` to also write `public/scad-manifest.json` listing every
file under `public/scad`, `public/fonts`, and `public/libraries` as `{ url, path }` (url =
public path served by Next, e.g. `/scad/carrier.scad`; path = FS path, e.g. `/scad/carrier.scad`).
Re-run `npm run sync:scad -- --local ../DarkroomSCAD` and confirm `public/scad-manifest.json` exists.

- [ ] **Step 10: Commit**

```bash
git add src/lib/openscad scripts/sync-scad.ts public/scad-manifest.json
git commit -m "feat: WASM render core, worker, and headless render proof"
```

---

### Task 6: Minimal render-and-download page (end-to-end slice)

Wires the worker to a single button. Hard-coded default config — no form yet. Proves the
full browser path: worker → render → STL → download.

**Files:**
- Create: `src/lib/openscad/client.ts` (typed worker client)
- Create: `src/app/page.tsx` (replace default)
- Test: `src/lib/openscad/client.test.ts` (message-protocol unit test with a mock worker)

**Interfaces:**
- Consumes: worker protocol from Task 5.
- Produces:
  - `class RenderClient { render(req: RenderRequest): Promise<RenderResult>; dispose(): void }`

- [ ] **Step 1: Write the failing test for the client protocol**

Create `src/lib/openscad/client.test.ts`:

```ts
import { describe, it, expect, vi } from "vitest";
import { RenderClient } from "./client";

class FakeWorker {
  onmessage: ((e: MessageEvent) => void) | null = null;
  posted: any[] = [];
  postMessage(msg: any) {
    this.posted.push(msg);
    // Echo a successful result on the next tick.
    queueMicrotask(() => {
      this.onmessage?.({
        data: {
          type: "result",
          id: msg.id,
          result: { stl: new Uint8Array([1]), log: "", durationMs: 1 },
        },
      } as MessageEvent);
    });
  }
  terminate = vi.fn();
}

describe("RenderClient", () => {
  it("resolves render() with the worker's result for the matching id", async () => {
    const worker = new FakeWorker();
    const client = new RenderClient(worker as unknown as Worker);
    const result = await client.render({ params: { Owner_Name: "X" }, quality: "preview" });
    expect(result.stl).toEqual(new Uint8Array([1]));
    expect(worker.posted[0].type).toBe("render");
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test -- client`
Expected: FAIL — `RenderClient` is not defined.

- [ ] **Step 3: Implement the worker client**

Create `src/lib/openscad/client.ts`:

```ts
import type { RenderRequest, RenderResult } from "./types";

type Pending = {
  resolve: (r: RenderResult) => void;
  reject: (e: Error) => void;
};

export class RenderClient {
  private worker: Worker;
  private pending = new Map<number, Pending>();
  private nextId = 1;

  constructor(worker: Worker) {
    this.worker = worker;
    this.worker.onmessage = (e: MessageEvent) => {
      const { type, id, result, message } = e.data;
      const p = this.pending.get(id);
      if (!p) return;
      this.pending.delete(id);
      if (type === "result") p.resolve(result as RenderResult);
      else p.reject(new Error(message ?? "Render failed"));
    };
  }

  render(req: RenderRequest): Promise<RenderResult> {
    const id = this.nextId++;
    return new Promise<RenderResult>((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.worker.postMessage({ type: "render", id, req });
    });
  }

  dispose() {
    this.worker.terminate();
    this.pending.clear();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test -- client`
Expected: PASS.

- [ ] **Step 5: Build the minimal page**

Replace `src/app/page.tsx`:

```tsx
"use client";

import { useRef, useState } from "react";
import { RenderClient } from "@/lib/openscad/client";
import { DEFAULT_FONT_FAMILY } from "@/config/fonts";

export default function Home() {
  const clientRef = useRef<RenderClient | null>(null);
  const [status, setStatus] = useState<string>("idle");

  function getClient(): RenderClient {
    if (!clientRef.current) {
      const worker = new Worker(new URL("../lib/openscad/worker.ts", import.meta.url), {
        type: "module",
      });
      clientRef.current = new RenderClient(worker);
    }
    return clientRef.current;
  }

  async function handleRender() {
    setStatus("rendering…");
    try {
      const result = await getClient().render({
        params: {
          Carrier_Type: "omega-d",
          Film_Format: "35mm",
          Orientation: "vertical",
          Top_or_Bottom: "bottom",
          Render_Quality: "final",
          Owner_Name: "DARKROOM",
          Fontface: DEFAULT_FONT_FAMILY,
        },
        quality: "final",
      });
      const blob = new Blob([result.stl], { type: "model/stl" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "omega-d_35mm_vertical_bottom.stl";
      a.click();
      URL.revokeObjectURL(url);
      setStatus(`done in ${Math.round(result.durationMs)}ms`);
    } catch (err) {
      setStatus(`error: ${(err as Error).message}`);
    }
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 p-8">
      <h1 className="text-2xl font-semibold">DarkroomSCAD Web — render core</h1>
      <button
        onClick={handleRender}
        className="rounded bg-emerald-500 px-6 py-3 font-medium text-black hover:bg-emerald-400"
      >
        Render &amp; download default carrier
      </button>
      <p className="text-sm text-zinc-400">{status}</p>
    </main>
  );
}
```

- [ ] **Step 6: Manual end-to-end verification**

Run: `npm run dev`
Open `http://localhost:3000`, click the button.
Expected: status shows "rendering…" then "done in …ms"; an STL downloads. Open the STL in a viewer (or OpenSCAD) and confirm it's a recognizable Omega-D 35mm carrier bottom with etched text.

- [ ] **Step 7: Commit**

```bash
git add src/lib/openscad/client.ts src/lib/openscad/client.test.ts src/app/page.tsx
git commit -m "feat: minimal browser render-and-download slice"
```

---

## Plan 1 Self-Review

- **Spec coverage (Plan 1 portion):** repo & stack (Task 1) ✓; file-sync & param parse (Tasks 2–3) ✓; WASM render engine + manifold + params JSON (Task 5) ✓; BOSL2 + fonts + Lucida remap (Task 4) ✓; `textmetrics` risk gate (Task 5 Step 7) ✓; empty-geometry detection (render.ts) ✓. Deferred to later plans by design: full param UI, conditional visibility, 3D viewer, ZIP/individual export, full theming, error UI polish, e2e tests.
- **Placeholder scan:** no TBDs; every code step has complete code. The one deliberately deferred detail — exact library-mount convention — is gated behind the integration test (Task 5 Step 7) with a concrete fallback, not a hand-wave.
- **Type consistency:** `RenderRequest` / `RenderResult` / `RenderParams` defined in `types.ts` (Task 5) and consumed unchanged in `render.ts`, `worker.ts`, `client.ts`. `parseCustomizer` signature consistent across Tasks 2–3. `buildParamSetJson(params, setName)` consistent. `DEFAULT_FONT_FAMILY` defined in Task 4, used in Tasks 5–6.

---

## Plans 2 & 3 (outline — detailed after Plan 1 lands)

These are intentionally outlined, not fully specced: their detail depends on what Task 5
teaches us (render timings, whether the `textmetrics` shim is needed, exact FS conventions).

### Plan 2 — Guided Customizer UI & Live Preview
- Curation overlay `config/carrier-ui.ts` (labels, grouping, advanced disclosure, font dropdown from `BUNDLED_FONTS`, `Lucida Console`→default remap).
- Build-time schema↔overlay consistency check (fails build on stale param references).
- Form components driven by schema+overlay; conditional visibility (custom-format fields, alignment-board type).
- Debounced preview pipeline (preview quality, single representative part) → react-three-fiber viewer (orbit/zoom/grid/auto-fit), themed materials, "preview quality" badge.
- Render cancellation (newest-wins) in `RenderClient`/worker.

### Plan 3 — Export, Theming & Error UX
- Part-enumeration helper (top/bottom/alignment board/text parts from current config) with unit tests.
- ZIP (default) vs individual export via `fflate`; meaningful filenames; export progress.
- Full theme system (dark/light/darkroom-safelight/high-contrast) via CSS custom properties + toggle, mirroring dorkroom tokens; Fraunces + Montserrat.
- Error UX: readable compile/render errors, WASM-load failure fallback, degenerate-geometry reporting surfaced in UI.
- Vercel deploy config + production smoke check; optional Playwright happy-path e2e.
