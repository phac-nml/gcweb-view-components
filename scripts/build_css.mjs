// Compile the gem's SCSS entrypoints to plain CSS next to them.
//
//   pnpm build:css          write gcweb.css and gcweb-components.css
//   pnpm build:css:check    fail if the committed CSS is out of date (CI)
//
// The compiled files are committed so Propshaft hosts can use the gem with no
// Sass toolchain. Font URLs stay relative ("fonts/…"), which resolves both for
// Propshaft (gcweb_view_components/fonts/…) and for bundlers.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as sass from "sass-embedded";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dir = path.join(root, "app/assets/stylesheets/gcweb_view_components");
const entries = ["gcweb", "gcweb-components"];
const check = process.argv.includes("--check");

const banner = (name) =>
  `/* gcweb_view_components — generated from ${name}.scss by \`pnpm build:css\`. Do not edit. */\n`;

let stale = false;

for (const name of entries) {
  const { css } = await sass.compileAsync(path.join(dir, `${name}.scss`), { style: "expanded" });
  const output = banner(name) + css + "\n";
  const target = path.join(dir, `${name}.css`);

  if (check) {
    const current = fs.existsSync(target) ? fs.readFileSync(target, "utf8") : "";
    if (current !== output) {
      console.error(`[build:css] ${path.relative(root, target)} is out of date. Run \`pnpm build:css\`.`);
      stale = true;
    } else {
      console.log(`[build:css] ${path.relative(root, target)} is up to date`);
    }
  } else {
    fs.writeFileSync(target, output);
    console.log(`[build:css] wrote ${path.relative(root, target)}`);
  }
}

if (stale) process.exit(1);
