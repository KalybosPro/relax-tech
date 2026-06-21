import puppeteer from 'puppeteer';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = join(__dirname, 'output');
if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });

const slides = [
  { file: 'linkedin.html', out: 'relax_image_picker_linkedin.png', w: 1080, h: 1350 },
  { file: 'linkedin_code.html', out: 'relax_image_picker_code.png', w: 1080, h: 1350 },
];

const browser = await puppeteer.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
});

for (const s of slides) {
  const htmlPath = join(__dirname, s.file);
  if (!existsSync(htmlPath)) { console.warn(`skip ${s.file} (missing)`); continue; }
  const page = await browser.newPage();
  await page.setViewport({ width: s.w, height: s.h, deviceScaleFactor: 2 });
  await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`, { waitUntil: 'networkidle0' });
  await new Promise(r => setTimeout(r, 1800));
  const out = join(outDir, s.out);
  await page.screenshot({ path: out, clip: { x: 0, y: 0, width: s.w, height: s.h } });
  console.log(`OK  ${s.out}`);
  await page.close();
}

await browser.close();
console.log('Done — images in assets/promo/output/');
