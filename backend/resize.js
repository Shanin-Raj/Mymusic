const sharp = require('sharp');
const path = require('path');

const input = path.join(__dirname, '..', 'musiclogo.jpeg');
const output512 = path.join(__dirname, 'public', 'icons', 'icon-512.png');
const output192 = path.join(__dirname, 'public', 'icons', 'icon-192.png');

async function resize() {
  try {
    await sharp(input)
      .resize(512, 512)
      .toFile(output512);
    console.log('✅ Created icon-512.png');

    await sharp(input)
      .resize(192, 192)
      .toFile(output192);
    console.log('✅ Created icon-192.png');
  } catch (err) {
    console.error('❌ Error resizing images:', err);
  }
}

resize();
