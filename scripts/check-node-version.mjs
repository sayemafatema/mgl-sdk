/**
 * Next.js 16 + toolchain expect a current Node LTS.
 * Fails fast with a clear message instead of opaque "Unexpected token ?" errors.
 */
const major = Number(process.version.slice(1).split('.')[0]);

if (!Number.isFinite(major) || major < 20) {
  console.error(
    `[mgl-sdk] Node.js 20+ is required (see package.json "engines"). You have ${process.version}.\n` +
      'Install Node 20 LTS: https://nodejs.org/ or run `nvm install` / `nvm use` (see .nvmrc).'
  );
  process.exit(1);
}
