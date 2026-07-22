/**
 * Founder-Badge: Checkerboard entfernen, transparent exportieren.
 * Usage: node scripts/process-founder-badge.mjs [input.png]
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const defaultInput = path.join(
  __dirname,
  '../assets/badges/v3/founder_source.png',
);
const output = path.join(__dirname, '../assets/badges/v3/founder.png');
const input = process.argv[2] ? path.resolve(process.argv[2]) : defaultInput;

function isCheckerboard(r, g, b, a) {
  if (a < 8) return true;
  const maxDiff = Math.max(Math.abs(r - g), Math.abs(g - b), Math.abs(r - b));
  if (maxDiff > 22) return false;
  const avg = (r + g + b) / 3;
  return avg > 160 && avg < 250;
}

function isNearWhite(r, g, b, a) {
  if (a < 8) return true;
  return r > 248 && g > 248 && b > 248;
}

function isBackground(r, g, b, a) {
  if (a < 8) return true;
  if (isCheckerboard(r, g, b, a)) return true;
  if (isNearWhite(r, g, b, a)) return true;
  // Schwarzer Export-Hintergrund ausserhalb der Badge-Scheibe.
  if (r < 28 && g < 28 && b < 32) return true;
  return false;
}

async function main() {
  if (!fs.existsSync(input)) {
    console.error('Input not found:', input);
    process.exit(1);
  }

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
    if (isBackground(r, g, b, a)) {
      pixels[i + 3] = 0;
    }
  }

  await sharp(pixels, {
    raw: { width: info.width, height: info.height, channels: 4 },
  })
    .png({ compressionLevel: 6, adaptiveFiltering: true })
    .toFile(output);

  console.log('OK founder.png');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
