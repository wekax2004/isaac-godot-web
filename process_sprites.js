
const Jimp = require('jimp');

async function processImage(inputPath, outputPath) {
    try {
        console.log(`Starting: ${inputPath}`);
        const image = await Jimp.read(inputPath);

        // Remove white background
        image.scan(0, 0, image.bitmap.width, image.bitmap.height, function (x, y, idx) {
            const r = this.bitmap.data[idx + 0];
            const g = this.bitmap.data[idx + 1];
            const b = this.bitmap.data[idx + 2];

            // If the pixel is very white, make it fully transparent
            if (r > 240 && g > 240 && b > 240) {
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
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/player_sprite_v2_1772732649696.png', out: 'D:/isaac-godot/assets/player_sprite_new.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/enemy_basic_v2_1772732672296.png', out: 'D:/isaac-godot/assets/enemy_basic.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/5cc6f686-4995-4b32-b6ec-465968c1e545/monstro_sprite_v2_1772732689317.png', out: 'D:/isaac-godot/assets/monstro_sprite.png' }
];

(async () => {
    for (const img of images) {
        await processImage(img.in, img.out);
    }
})();
