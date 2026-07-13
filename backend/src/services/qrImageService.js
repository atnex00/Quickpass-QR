const path = require('path');
const fs = require('fs');
const QRCode = require('qrcode');
const sharp = require('sharp');

const LOGO_PATH = path.join(__dirname, '../../uploads/logo.png');
const OUTPUT_DIR = path.join(__dirname, '../../uploads/qr_codes');
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}
const CELL_SIZE = 10;
const MARGIN_MODULES = 8;
const LOGO_SIZE_FRACTION = 0.28;
const LOGO_MARGIN = 4;

function isFinder(row, col, n) {
  const inTL = row < 7 && col < 7;
  const inTR = row < 7 && col >= n - 7;
  const inBL = row >= n - 7 && col < 7;
  if (!inTL && !inTR && !inBL) return false;
  const r = row < 7 ? row : row - (n - 7);
  const c = inTL ? col : col - (n - 7);
  const inOuter = r === 0 || r === 6 || c === 0 || c === 6;
  const inCenter = r >= 2 && r <= 4 && c >= 2 && c <= 4;
  return inOuter || inCenter;
}

function buildSvg(matrix, margin, cellSize, accentColor) {
  const n = matrix.length;
  const pad = margin * cellSize;
  const totalSize = (n + margin * 2) * cellSize;

  const cells = [];
  const finderOuter = [];
  const finderCenter = [];

  for (let row = 0; row < n; row++) {
    for (let col = 0; col < n; col++) {
      if (!matrix[row][col]) continue;
      const x = pad + col * cellSize;
      const y = pad + row * cellSize;

      if (isFinder(row, col, n)) {
        const localRow = row < 7 ? row : row >= n - 7 ? row - (n - 7) : 0;
        const localCol = col < 7 ? col : col >= n - 7 ? col - (n - 7) : 0;
        const inOuter = localRow === 0 || localRow === 6 || localCol === 0 || localCol === 6;
        const inCenter = localRow >= 2 && localRow <= 4 && localCol >= 2 && localCol <= 4;
        if (inOuter) {
          finderOuter.push(`<rect x="${x}" y="${y}" width="${cellSize}" height="${cellSize}" rx="${cellSize * 0.35}" fill="${accentColor}"/>`);
        } else if (inCenter) {
          finderCenter.push(`<circle cx="${x + cellSize / 2}" cy="${y + cellSize / 2}" r="${cellSize * 0.4}" fill="${accentColor}"/>`);
        }
      } else {
        const cx = x + cellSize / 2;
        const cy = y + cellSize / 2;
        cells.push(`<circle cx="${cx}" cy="${cy}" r="${cellSize * 0.4}" fill="#000000"/>`);
      }
    }
  }

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${totalSize}" height="${totalSize}" viewBox="0 0 ${totalSize} ${totalSize}">`,
    `<rect width="${totalSize}" height="${totalSize}" fill="#ffffff"/>`,
    ...cells,
    ...finderOuter,
    ...finderCenter,
    '</svg>',
  ].join('');
}

async function generateQrImage(qrData, type, leaveId) {
  const qr = QRCode.create(qrData, { errorCorrectionLevel: 'H' });
  const matrix = qr.modules;
  const n = matrix.length;
  const totalSize = (n + MARGIN_MODULES * 2) * CELL_SIZE;

  const accentColor = type === 'OUT' ? '#fbbf24' : '#0d9488';

  const svg = buildSvg(matrix, MARGIN_MODULES, CELL_SIZE, accentColor);

  let img = sharp(Buffer.from(svg)).png();

  const logoPath = LOGO_PATH;
  if (fs.existsSync(logoPath)) {
    const logoSize = Math.round(totalSize * LOGO_SIZE_FRACTION);
    const logoPadding = LOGO_MARGIN;
    const logoInner = logoSize - logoPadding * 2;

    const logoBuffer = await sharp(logoPath)
      .resize(logoInner, logoInner, { fit: 'inside' })
      .toBuffer();

    const logoWithPadding = await sharp({
      create: {
        width: logoSize,
        height: logoSize,
        channels: 4,
        background: { r: 255, g: 255, b: 255, alpha: 1 },
      },
    })
      .composite([{ input: logoBuffer, top: logoPadding, left: logoPadding }])
      .png()
      .toBuffer();

    const offset = Math.round((totalSize - logoSize) / 2);
    img = img.composite([{ input: logoWithPadding, top: offset, left: offset }]);
  }

  const filename = `${leaveId}_${type.toLowerCase()}.png`;
  const outputPath = path.join(OUTPUT_DIR, filename);
  await img.toFile(outputPath);

  return `/uploads/qr_codes/${filename}`;
}

function deleteQrImages(leaveId) {
  ['out', 'in'].forEach((type) => {
    const p = path.join(OUTPUT_DIR, `${leaveId}_${type}.png`);
    if (fs.existsSync(p)) fs.unlinkSync(p);
  });
}

module.exports = { generateQrImage, deleteQrImages };
