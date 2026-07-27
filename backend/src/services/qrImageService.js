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

async function generateQrImage(qrData, type, leaveId) {
  const qrBuf = await QRCode.toBuffer(qrData, {
    errorCorrectionLevel: 'H',
    type: 'png',
    scale: CELL_SIZE,
    margin: MARGIN_MODULES,
    color: {
      dark: type === 'OUT' ? '#fbbf24' : '#0d9488',
      light: '#ffffff',
    },
  });

  const meta = await sharp(qrBuf).metadata();
  const totalSize = meta.width ?? 370;

  let img = sharp(qrBuf).png();

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
