/**
 * Cairo-EPS (Pfad-only) → PNG. Usage:
 * node scripts/eps-to-png.mjs input.eps output.png [size]
 */
import fs from 'fs';
import { Resvg } from '@resvg/resvg-js';

const [, , inputPath, outputPath, sizeArg] = process.argv;
if (!inputPath || !outputPath) {
  console.error('Usage: node scripts/eps-to-png.mjs <input.eps> <output.png> [size]');
  process.exit(1);
}

const size = Number(sizeArg) || 1024;
const eps = fs.readFileSync(inputPath, 'latin1');
const start = eps.indexOf('%%EndPageSetup');
const end = eps.indexOf('showpage', start);
if (start < 0 || end < 0) {
  console.error('Could not find page content in EPS');
  process.exit(1);
}

const bbox = eps.match(/%%BoundingBox:\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/);
const width = bbox ? Number(bbox[3]) - Number(bbox[1]) : 941;
const height = bbox ? Number(bbox[4]) - Number(bbox[2]) : 941;

const body = eps.slice(start + '%%EndPageSetup'.length, end)
  // Drop clip/setup wrappers we handle via viewBox
  .replace(/q\s+0\s+0\s+[\d.]+\s+[\d.]+\s+rectclip/g, '')
  .replace(/1\s+0\s+0\s+-1\s+0\s+[\d.]+\s+cm/g, '')
  .replace(/\bq\b/g, '')
  .replace(/\bQ\b/g, '');

const tokens = body.match(/-?(?:\d+\.\d+|\d+|\.\d+)(?:[eE][+-]?\d+)?|[a-zA-Z*]+/g) || [];

const paths = [];
let fill = 'rgb(0,0,0)';
let d = '';
const stack = [];

function flushPath() {
  if (!d.trim()) return;
  paths.push({ d: d.trim(), fill });
  d = '';
}

for (let i = 0; i < tokens.length; i++) {
  const t = tokens[i];
  if (t === 'rg') {
    flushPath();
    const b = Number(stack.pop());
    const g = Number(stack.pop());
    const r = Number(stack.pop());
    fill = `rgb(${Math.round(r * 255)},${Math.round(g * 255)},${Math.round(b * 255)})`;
  } else if (t === 'm') {
    const y = Number(stack.pop());
    const x = Number(stack.pop());
    d += `M ${x} ${y} `;
  } else if (t === 'l') {
    const y = Number(stack.pop());
    const x = Number(stack.pop());
    d += `L ${x} ${y} `;
  } else if (t === 'c') {
    const y3 = Number(stack.pop());
    const x3 = Number(stack.pop());
    const y2 = Number(stack.pop());
    const x2 = Number(stack.pop());
    const y1 = Number(stack.pop());
    const x1 = Number(stack.pop());
    d += `C ${x1} ${y1} ${x2} ${y2} ${x3} ${y3} `;
  } else if (t === 'h') {
    d += 'Z ';
  } else if (t === 'f' || t === 'f*') {
    flushPath();
  } else if (t === 'n') {
    d = '';
  } else if (!Number.isNaN(Number(t))) {
    stack.push(t);
  }
}
flushPath();

// Skip only light full-canvas fills (white/cream/checkerboard). Keep dark badge disk.
const filtered = paths.filter((p) => {
  const nums = p.d.match(/-?\d+(?:\.\d+)?/g)?.map(Number) || [];
  if (nums.length < 8) return true;
  const xs = nums.filter((_, i) => i % 2 === 0);
  const ys = nums.filter((_, i) => i % 2 === 1);
  const spanX = Math.max(...xs) - Math.min(...xs);
  const spanY = Math.max(...ys) - Math.min(...ys);
  const coversCanvas = spanX > width * 0.95 && spanY > height * 0.95;
  if (!coversCanvas) return true;
  const m = p.fill.match(/rgb\((\d+),(\d+),(\d+)\)/);
  if (!m) return true;
  const avg = (Number(m[1]) + Number(m[2]) + Number(m[3])) / 3;
  // Full-bleed light backgrounds only — dark canvas pad is cut via circular mask later.
  return avg < 80;
});

const svgPaths = filtered
  .map((p) => `<path d="${p.d}" fill="${p.fill}" fill-rule="evenodd"/>`)
  .join('\n');

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
${svgPaths}
</svg>`;

const resvg = new Resvg(svg, {
  fitTo: { mode: 'width', value: size },
  background: 'rgba(0,0,0,0)',
});
const png = resvg.render().asPng();

// Circular alpha: remove dark square padding outside the badge disk.
const sharp = (await import('sharp')).default;
const { data, info } = await sharp(png)
  .ensureAlpha()
  .raw()
  .toBuffer({ resolveWithObject: true });

const cx = (info.width - 1) / 2;
const cy = (info.height - 1) / 2;
const radius = Math.min(cx, cy) * 0.98;
const pixels = Buffer.from(data);
for (let y = 0; y < info.height; y++) {
  for (let x = 0; x < info.width; x++) {
    const dx = x - cx;
    const dy = y - cy;
    if (dx * dx + dy * dy > radius * radius) {
      pixels[(y * info.width + x) * 4 + 3] = 0;
    }
  }
}

await sharp(pixels, {
  raw: { width: info.width, height: info.height, channels: 4 },
})
  .png()
  .toFile(outputPath);

console.log(`OK ${outputPath} (${filtered.length} paths, ${size}px)`);
