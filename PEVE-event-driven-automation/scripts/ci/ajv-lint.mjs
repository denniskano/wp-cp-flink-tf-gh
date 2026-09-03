#!/usr/bin/env node
// Fallback si no hay check-jsonschema. Uso: node ajv-lint.mjs <schema.json> <file.yaml>...
import { readFileSync } from "node:fs";
import { basename } from "node:path";
import Ajv from "ajv";
import { load as loadYaml } from "js-yaml";

const [schemaPath, ...files] = process.argv.slice(2);
if (!schemaPath || files.length === 0) {
  console.error("uso: ajv-lint.mjs <schema.json> <file.yaml> [...]");
  process.exit(2);
}

const ajv = new Ajv({ allErrors: true, strict: false });
const schema = JSON.parse(readFileSync(schemaPath, "utf8"));
const validate = ajv.compile(schema);

let failed = false;
for (const file of files) {
  const doc = loadYaml(readFileSync(file, "utf8"));
  if (validate(doc)) {
    continue;
  }
  failed = true;
  console.error(`${file}:`);
  for (const err of validate.errors || []) {
    const where = err.instancePath || "/";
    console.error(`  ${where} ${err.message} (${err.keyword})`);
  }
}

if (failed) {
  process.exit(1);
}
console.log(`OK ajv ${basename(schemaPath)} (${files.length} yaml)`);
