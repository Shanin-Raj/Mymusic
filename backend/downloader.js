const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

async function downloadSong(songName, artistName, directUrl = null) {
  const query = directUrl || `${songName} ${artistName} lyrics`;
  const outputDir = path.join(__dirname, 'downloads');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
  }

  const fileName = `${songName.replace(/[/\\?%*:|"<>]/g, '-')}.m4a`;
  const outputPath = path.join(outputDir, fileName);

  // Use python -m yt_dlp to ensure it's found
  const args = [
    '-m', 'yt_dlp',
    '--extract-audio',
    '--audio-format', 'm4a',
    '--no-playlist'
  ];

  const ffmpegLocation = process.env.FFMPEG_LOCATION;
  if (ffmpegLocation) {
    args.push('--ffmpeg-location', ffmpegLocation);
  }

  args.push('-o', outputPath, directUrl ? directUrl : `ytsearch1:${query}`);

  return new Promise((resolve, reject) => {
    console.log(`🚀 yt-dlp args: ${args.join(' ')}`);
    const child = spawn('python3', args);

    child.stdout.on('data', (data) => {
      const output = data.toString();
      if (output.includes('%')) {
        // Log progress if available
        process.stdout.write(`\rProgress: ${output.trim().split(' ').filter(x => x.includes('%'))[0] || ''}    `);
      }
    });

    child.stderr.on('data', (data) => {
      const output = data.toString().trim();
      if (output) {
        console.error(`stderr: ${output}`);
      }
    });

    child.on('close', (code) => {
      if (code === 0) {
        console.log(`\n✅ Successfully downloaded: ${fileName}`);
        resolve(outputPath);
      } else {
        console.error(`\n❌ Failed to download with exit code ${code}`);
        reject(new Error(`Exit code ${code}`));
      }
    });
  });
}

module.exports = { downloadSong };
