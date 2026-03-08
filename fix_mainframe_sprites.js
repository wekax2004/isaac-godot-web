const Jimp = require('jimp');
const path = require('path');
const fs = require('fs');

const artifactsDir = 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4';
const outputDir = 'D:/isaac-godot/assets';

const spriteConfigs = [
    { in: 'player_rogue_instance_raw_1772883997425.png', out: 'player_rogue_instance.png', targetSize: 128 },
    { in: 'chaser_mainframe_raw_1772883735640.png', out: 'enemy_chaser_mainframe.png', targetSize: 128 },
    { in: 'shooter_mainframe_raw_1772883750502.png', out: 'enemy_shooter_mainframe.png', targetSize: 128 },
    { in: 'tank_mainframe_raw_1772883766620.png', out: 'enemy_tank_mainframe.png', targetSize: 192 },
    { in: 'fly_mainframe_raw_1772883783675.png', out: 'enemy_fly_mainframe.png', targetSize: 64 }
];

async function removeBackgroundsAggressive(image, tolerance = 60) {
    const w = image.bitmap.width;
    const h = image.bitmap.height;

    // 1. Identify ALL colors on the outer border (10 pixels in)
    const bgColorsSet = new Set();
    const border = 10;

    function addColor(x, y) {
        const idx = image.getPixelIndex(x, y);
        const r = image.bitmap.data[idx + 0];
        const g = image.bitmap.data[idx + 1];
        const b = image.bitmap.data[idx + 2];
        const key = `${Math.floor(r / 8) * 8},${Math.floor(g / 8) * 8},${Math.floor(b / 8) * 8}`;
        bgColorsSet.add(key);
    }

    for (let x = 0; x < w; x++) {
        for (let y = 0; y < border; y++) addColor(x, y);
        for (let y = h - border; y < h; y++) addColor(x, y);
    }
    for (let y = 0; y < h; y++) {
        for (let x = 0; x < border; x++) addColor(x, y);
        for (let x = w - border; x < w; x++) addColor(x, y);
    }

    const bgColors = Array.from(bgColorsSet).map(s => {
        const [r, g, b] = s.split(',').map(Number);
        return { r, g, b };
    });

    console.log(`Global Purge: Identifed ${bgColors.length} background clusters.`);

    // 2. Global sweep: if any pixel matches a border color cluster, nuke it.
    // This catches "trapped" checkerboard pixels.
    image.scan(0, 0, w, h, function (x, y, idx) {
        const r = this.bitmap.data[idx + 0];
        const g = this.bitmap.data[idx + 1];
        const b = this.bitmap.data[idx + 2];

        for (const target of bgColors) {
            const dist = Math.abs(r - target.r) + Math.abs(g - target.g) + Math.abs(b - target.b);
            if (dist <= tolerance) {
                this.bitmap.data[idx + 3] = 0;
                break;
            }
        }
    });

    // 3. Flood fill cleanup from edges to ensure all outer transparency is truly empty
    const visited = new Uint8Array(w * h);
    const queue = [];
    for (let x = 0; x < w; x++) { queue.push([x, 0], [x, h - 1]); visited[0 * w + x] = 1; visited[(h - 1) * w + x] = 1; }
    for (let y = 0; y < h; y++) { queue.push([0, y], [w - 1, y]); visited[y * w + 0] = 1; visited[y * w + (w - 1)] = 1; }

    while (queue.length > 0) {
        const [cx, cy] = queue.shift();
        const idx = (cy * w + cx) * 4;
        if (image.bitmap.data[idx + 3] === 0) {
            const neighbors = [[cx + 1, cy], [cx - 1, cy], [cx, cy + 1], [cx, cy - 1]];
            for (const [nx, ny] of neighbors) {
                if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[ny * w + nx]) {
                    visited[ny * w + nx] = 1;
                    queue.push([nx, ny]);
                }
            }
        }
    }
}

async function processSprite(config) {
    const inputPath = path.join(artifactsDir, config.in);
    const outputPath = path.join(outputDir, config.out);

    try {
        console.log(`Processing: ${config.in} -> ${config.out}`);
        const image = await Jimp.read(inputPath);

        // Remove background clusters globally
        await removeBackgroundsAggressive(image, 55);

        // Alpha Clamping (Nearest-ready)
        image.scan(0, 0, image.bitmap.width, image.bitmap.height, function (x, y, idx) {
            const alpha = this.bitmap.data[idx + 3];
            if (alpha < 128) {
                this.bitmap.data[idx + 3] = 0;
            } else {
                this.bitmap.data[idx + 3] = 255;
            }
        });

        // Autocrop
        image.autocrop();

        // Resize
        image.resize(config.targetSize, Jimp.AUTO);

        await image.writeAsync(outputPath);

        // Forced Re-import
        const importFile = outputPath + '.import';
        if (fs.existsSync(importFile)) fs.unlinkSync(importFile);

        console.log(`Successfully saved: ${config.out}`);
    } catch (err) {
        console.error(`Error processing ${config.in}:`, err);
    }
}

async function main() {
    for (const config of spriteConfigs) {
        if (fs.existsSync(path.join(artifactsDir, config.in))) {
            await processSprite(config);
        }
    }
}

main();
