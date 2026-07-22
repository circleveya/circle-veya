/**
 * Badge-Assets schärfen + Checkerboard-Hintergrund entfernen.
 * Usage: node scripts/sharpen-badges.mjs
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dir = path.join(__dirname, '../assets/badges/v3');

function isCheckerboard(r, g, b, a) {
  if (a < 8) return true;
  const maxDiff = Math.max(Math.abs(r - g), Math.abs(g - b), Math.abs(r - b));
  if (maxDiff > 18) return false;
  const avg = (r + g + b) / 3;
  return avg > 175 && avg < 245;
}

async function processBadge(file) {
  const input = path.join(dir, file);
  const { data, info } = await sharp(input)
    .ensureAlpha()
    .resize(1024, 1024, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
      kernel: sharp.kernel.lanczos3,
    })
    .raw()
    .toBuffer({ resolveWithObject: true });

  const pixels = Buffer.from(data);
  for (let i = 0; i < pixels.length; i += 4) {
    const r = pixels[i];
    const g = pixels[i + 1];
    const b = pixels[i + 2];
    const a = pixels[i + 3];
    if (isCheckerboard(r, g, b, a)) {
      pixels[i + 3] = 0;
    }
  }

  await sharp(pixels, {
    raw: { width: info.width, height: info.height, channels: 4 },
  })
    .sharpen({ sigma: 1.0, m1: 0.5, m2: 2.5, x1: 2, y2: 10 })
    .png({ compressionLevel: 6, adaptiveFiltering: true })
    .toFile(input);

  console.log(`OK ${file}`);
}

const files = fs.readdirSync(dir).filter((f) => f.endsWith('.png'));
for (const file of files) {
  await processBadge(file);
}

console.log(`Done: ${files.length} badges`);
