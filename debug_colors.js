const Jimp = require('jimp');

async function debugColors(file) {
    const img = await Jimp.read(file);
    const w = img.bitmap.width;
    const h = img.bitmap.height;

    const corners = [
        [0, 0], [w - 1, 0], [0, h - 1], [w - 1, h - 1], [2, 2], [w - 3, 2]
    ];

    console.log(`File: ${file}`);
    corners.forEach(([x, y]) => {
        const idx = (y * w + x) * 4;
        const r = img.bitmap.data[idx];
        const g = img.bitmap.data[idx + 1];
        const b = img.bitmap.data[idx + 2];
        const a = img.bitmap.data[idx + 3];
        console.log(`Pixel (${x},${y}): R:${r} G:${g} B:${b} A:${a}`);
    });
}

debugColors('d:/isaac-godot/assets/player_rogue_instance.png');
debugColors('d:/isaac-godot/assets/enemy_chaser_mainframe.png');
