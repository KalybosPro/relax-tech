import puppeteer from 'puppeteer';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const htmlPath  = join(__dirname, 'banner.html');
const outDir    = join(__dirname, 'output');

if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });

const browser = await puppeteer.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
});

const page = await browser.newPage();
await page.setViewport({ width: 1200, height: 900, deviceScaleFactor: 2 });
await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`, { waitUntil: 'networkidle0' });
await new Promise(r => setTimeout(r, 1800));

const out = join(outDir, 'banner.png');
await page.screenshot({ path: out, clip: { x: 0, y: 0, width: 1200, height: 900 } });
console.log(`✅  banner.png  →  ${out}`);

await browser.close();
