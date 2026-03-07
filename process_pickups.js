
const Jimp = require('jimp');

function colorDistance(c1, c2) {
    return Math.abs(c1.r - c2.r) + Math.abs(c1.g - c2.g) + Math.abs(c1.b - c2.b);
}

async function removeGreen(inputPath, outputPath, targetSize) {
    try {
        console.log(`Processing: ${inputPath}`);
        const image = await Jimp.read(inputPath);
        const w = image.bitmap.width;
        const h = image.bitmap.height;

        // Let's rely entirely on chroma-keying green because these new images have perfect #00ff00 background
        image.scan(0, 0, w, h, function (x, y, idx) {
            const r = this.bitmap.data[idx + 0];
            const g = this.bitmap.data[idx + 1];
            const b = this.bitmap.data[idx + 2];

            // Pure neon green check
            if (g > 200 && r < 50 && b < 50) {
                this.bitmap.data[idx + 3] = 0;
            }
            // Very aggressive fringe check: if green is dominant
            else if (g > r + 50 && g > b + 50 && g > 120) {
                this.bitmap.data[idx + 3] = 0;
            }
        });

        // Resize to target size perfectly
        image.resize(targetSize, Jimp.AUTO);
        await image.writeAsync(outputPath);
        console.log(`Saved: ${outputPath}`);
    } catch (e) {
        console.error(`Error processing ${inputPath}: ${e.message}`);
    }
}

async function processAll() {
    await removeGreen('C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/player_sprite_v4_1772740516311.png', 'D:/isaac-godot/assets/player_sprite_new.png', 256);
    await removeGreen('C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/heart_v2_1772740532426.png', 'D:/isaac-godot/assets/pickup_heart.png', 128);
    await removeGreen('C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/coin_v2_1772740573789.png', 'D:/isaac-godot/assets/pickup_coin.png', 128);
}

processAll();
