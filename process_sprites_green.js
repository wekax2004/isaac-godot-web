
const Jimp = require('jimp');

async function processImage(inputPath, outputPath) {
    try {
        console.log(`Starting: ${inputPath}`);
        const image = await Jimp.read(inputPath);

        // Remove green background
        image.scan(0, 0, image.bitmap.width, image.bitmap.height, function (x, y, idx) {
            const r = this.bitmap.data[idx + 0];
            const g = this.bitmap.data[idx + 1];
            const b = this.bitmap.data[idx + 2];

            // Chroma key neon green
            if (g > 150 && r < 100 && b < 100) {
                this.bitmap.data[idx + 3] = 0;
            }
            // Aggressive fringe removal (if G is significantly dominant)
            else if (g > r + 30 && g > b + 30 && g > 100) {
                this.bitmap.data[idx + 3] = 0;
            }
        });

        await image.writeAsync(outputPath);
        console.log(`Success processing to: ${outputPath}`);
    } catch (e) {
        console.error(`Error processing ${inputPath}: ${e.message}`);
    }
}

const images = [
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/player_sprite_v3_1772733632137.png', out: 'D:/isaac-godot/assets/player_sprite_new.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/enemy_basic_v3_1772733646258.png', out: 'D:/isaac-godot/assets/enemy_basic.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/monstro_sprite_v3_1772733662568.png', out: 'D:/isaac-godot/assets/monstro_sprite.png' }
];

(async () => {
    for (const img of images) {
        await processImage(img.in, img.out);
    }
})();
