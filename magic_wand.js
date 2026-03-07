
const Jimp = require('jimp');

function colorDistance(c1, c2) {
    return Math.abs(c1.r - c2.r) + Math.abs(c1.g - c2.g) + Math.abs(c1.b - c2.b);
}

async function magicWand(inputPath, outputPath, tolerance = 30) {
    try {
        console.log(`Processing: ${inputPath}`);
        const image = await Jimp.read(inputPath);
        const w = image.bitmap.width;
        const h = image.bitmap.height;

        // Get background color from top-left pixel
        const bgIdx = 0; // (0,0) is index 0
        const bgR = image.bitmap.data[bgIdx + 0];
        const bgG = image.bitmap.data[bgIdx + 1];
        const bgB = image.bitmap.data[bgIdx + 2];
        const bgColor = { r: bgR, g: bgG, b: bgB };

        const visited = new Uint8Array(w * h);
        const queue = [0]; // Store index = y * w + x
        visited[0] = 1;

        while (queue.length > 0) {
            const current = queue.shift();
            const cx = current % w;
            const cy = Math.floor(current / w);

            // Make it transparent
            const pixelIdx = (cy * w + cx) * 4;
            image.bitmap.data[pixelIdx + 3] = 0;

            // Check neighbors
            const neighbors = [
                { x: cx + 1, y: cy },
                { x: cx - 1, y: cy },
                { x: cx, y: cy + 1 },
                { x: cx, y: cy - 1 }
            ];

            for (const n of neighbors) {
                if (n.x >= 0 && n.x < w && n.y >= 0 && n.y < h) {
                    const nIdx = n.y * w + n.x;
                    if (!visited[nIdx]) {
                        visited[nIdx] = 1;
                        const pIdx = nIdx * 4;
                        const pColor = {
                            r: image.bitmap.data[pIdx + 0],
                            g: image.bitmap.data[pIdx + 1],
                            b: image.bitmap.data[pIdx + 2]
                        };

                        if (colorDistance(bgColor, pColor) <= tolerance) {
                            queue.push(nIdx);
                        }
                    }
                }
            }
        }

        // Clean up any remaining neon green if this is a green screen image
        if (bgColor.g > 150 && bgColor.r < 100 && bgColor.b < 100) {
            image.scan(0, 0, w, h, function (x, y, idx) {
                const r = this.bitmap.data[idx + 0];
                const g = this.bitmap.data[idx + 1];
                const b = this.bitmap.data[idx + 2];
                // Remove pure neon green
                if (g > 150 && r < 100 && b < 100) {
                    this.bitmap.data[idx + 3] = 0;
                }
                // Antialiasing cleanup
                if (g > r + 30 && g > b + 30 && g > 100) {
                    this.bitmap.data[idx + 3] = 0;
                }
            });
        }

        // Downscale images slightly to fit the game better 
        image.resize(256, Jimp.AUTO);

        await image.writeAsync(outputPath);
        console.log(`Saved: ${outputPath}`);
    } catch (e) {
        console.error(`Error processing ${inputPath}: ${e.message}`);
    }
}

const images = [
    // Use the V2 images the user liked, doing flood-fill to save the white heads
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/player_sprite_v2_1772732649696.png', out: 'D:/isaac-godot/assets/player_sprite_new.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/enemy_basic_v2_1772732672296.png', out: 'D:/isaac-godot/assets/enemy_basic.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/monstro_sprite_v2_1772732689317.png', out: 'D:/isaac-godot/assets/monstro_sprite.png' }
];

(async () => {
    for (const img of images) {
        await magicWand(img.in, img.out, 15); // Low tolerance to preserve white body
    }
})();
