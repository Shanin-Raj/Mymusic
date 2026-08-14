const { spawn, spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

async function downloadSong(songName, artistName, directUrl = null) {
  const cleanSong = (songName || '').replace(/["'“”`]/g, ' ').replace(/\s+/g, ' ').trim();
  const cleanArtist = (artistName || '').replace(/["'“”`]/g, ' ').replace(/\s+/g, ' ').trim();
  const query = directUrl || `${cleanSong} ${cleanArtist} lyrics`;
  const outputDir = path.join(__dirname, 'downloads');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const cleanFileName = (songName || 'song').replace(/[/\\?%*:|"<>]/g, '-').trim();
  const fileName = `${cleanFileName}.m4a`;
  const outputPath = path.join(outputDir, fileName);

  const baseArgs = [
    '--extract-audio',
    '--audio-format', 'm4a',
    '--no-playlist',
    '--js-runtimes', 'node',
    '--extractor-args', 'youtube:player_client=ios,android,web',
    '--no-check-certificates'
  ];

  const ffmpegLocation = process.env.FFMPEG_LOCATION;
  if (ffmpegLocation) {
    baseArgs.push('--ffmpeg-location', ffmpegLocation);
  }

  baseArgs.push('-o', outputPath, '--', directUrl ? directUrl : `ytsearch1:${query}`);

  // Determine whether to run yt-dlp directly or via python module
  let cmd = 'yt-dlp';
  let args = [...baseArgs];

  try {
    const check = spawnSync('yt-dlp', ['--version']);
    if (check.status !== 0) {
      throw new Error('yt-dlp returned non-zero status');
    }
  } catch (err) {
    console.log('⚠️ yt-dlp direct command not available, falling back to python module...');
    cmd = process.platform === 'win32' ? 'python' : 'python3';
    args = ['-m', 'yt_dlp', ...baseArgs];
  }

  return new Promise((resolve, reject) => {
    console.log(`🚀 Spawning: ${cmd} ${args.join(' ')}`);
    const child = spawn(cmd, args);

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
