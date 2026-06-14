import puppeteer from 'puppeteer';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const htmlPath  = join(__dirname, 'slides.html');
const outDir    = join(__dirname, 'output');

if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });

const browser = await puppeteer.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
});

const page = await browser.newPage();
await page.setViewport({ width: 1080, height: 1350, deviceScaleFactor: 2 });
await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`, { waitUntil: 'networkidle0' });

// wait for Google Fonts (timeout gracefully if offline)
await new Promise(r => setTimeout(r, 1800));

for (let i = 1; i <= 6; i++) {
  const el = await page.$(`#slide-${i}`);
  if (!el) { console.error(`#slide-${i} not found`); continue; }

  const out = join(outDir, `slide_${i}.png`);
  await el.screenshot({ path: out, omitBackground: false });
  console.log(`✅  slide_${i}.png  →  ${out}`);
}

await browser.close();
console.log('\nDone — 5 slides generated in assets/carousel/output/');
