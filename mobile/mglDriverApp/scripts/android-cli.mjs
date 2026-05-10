import { writeFileSync, existsSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { spawnSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '..');
const androidDir = join(projectRoot, 'android');

function escapeSdkDirForProps(p) {
  if (process.platform !== 'win32') return p;
  return p.replace(/\\/g, '\\\\').replace(':', '\\:');
}

function adbPath(sdkDir) {
  const name = process.platform === 'win32' ? 'adb.exe' : 'adb';
  return join(sdkDir, 'platform-tools', name);
}

function defaultSdkDir() {
  const a = process.env.ANDROID_HOME || process.env.ANDROID_SDK_ROOT;
  if (a && existsSync(adbPath(a))) return a;
  const guess = join(process.env.LOCALAPPDATA || '', 'Android', 'Sdk');
  return guess;
}

function findJavaHome() {
  const javaBin = process.platform === 'win32' ? 'java.exe' : 'java';
  const check = (h) => h && existsSync(join(h, 'bin', javaBin));

  if (check(process.env.JAVA_HOME)) return process.env.JAVA_HOME;

  const pf = process.env.PROGRAMFILES || 'C:\\Program Files';
  const pfx86 = process.env['PROGRAMFILES(X86)'] || '';
  const candidates = [
    join(pf, 'Android', 'Android Studio', 'jbr'),
    join(pfx86, 'Android', 'Android Studio', 'jbr'),
    join(process.env.LOCALAPPDATA || '', 'Programs', 'Android Studio', 'jbr'),
    join(pf, 'JetBrains', 'Android Studio', 'jbr'),
  ];

  for (const c of candidates) {
    if (check(c)) return c;
  }

  const adoptium = join(pf, 'Eclipse Adoptium');
  try {
    const sub = readdirSync(adoptium);
    const jdk17 = sub
      .filter((n) => /^jdk-17[\w.-]*$/i.test(n) || /^jdk-21[\w.-]*$/i.test(n))
      .sort()
      .map((n) => join(adoptium, n));
    for (const c of jdk17) {
      if (check(c)) return c;
    }
  } catch {
    /* ignore */
  }

  return null;
}

const sdk = defaultSdkDir();
if (!existsSync(adbPath(sdk))) {
  console.error(
    'Android SDK not found. Install Android Studio or set ANDROID_HOME to your Sdk folder.',
  );
  process.exit(1);
}

writeFileSync(join(androidDir, 'local.properties'), `sdk.dir=${escapeSdkDirForProps(sdk)}\n`);

const javaHome = findJavaHome();
if (!javaHome) {
  console.error(
    'JDK not found. Install JDK 17+ (e.g. Temurin), full Android Studio (includes JBR), or set JAVA_HOME.',
  );
  process.exit(1);
}

const platformTools = join(sdk, 'platform-tools');
const sep = process.platform === 'win32' ? ';' : ':';
const pathVal = process.env.PATH || process.env.Path || '';
const pathPrefix = `${platformTools}${sep}${pathVal}`;

const env = {
  ...process.env,
  ANDROID_HOME: sdk,
  ANDROID_SDK_ROOT: sdk,
  JAVA_HOME: javaHome,
  PATH: pathPrefix,
};
if (process.platform === 'win32') {
  env.Path = pathPrefix;
}

const passthrough = process.argv.slice(2);
if (!passthrough.length) {
  console.error('Usage: node scripts/android-cli.mjs <react-native-args…>');
  process.exit(1);
}

const result = spawnSync('npx', ['react-native', ...passthrough], {
  cwd: projectRoot,
  env,
  stdio: 'inherit',
  shell: process.platform === 'win32',
});

process.exit(result.status === null ? 1 : result.status);
