
const Jimp = require('jimp');
const fs = require('fs');
const path = require('path');

async function removeGreen(inputPath, outputPath) {
    try {
        if (!fs.existsSync(inputPath)) {
            console.error(`Error: File not found at ${inputPath}`);
            return;
        }
        const image = await Jimp.read(inputPath);

        image.scan(0, 0, image.bitmap.width, image.bitmap.height, function (x, y, idx) {
            const r = this.bitmap.data[idx + 0];
            const g = this.bitmap.data[idx + 1];
            const b = this.bitmap.data[idx + 2];

            // Remove neon green (high G, low R and B)
            if (g > 150 && r < 120 && b < 120) {
                this.bitmap.data[idx + 3] = 0;
            }
        });

        await image.writeAsync(outputPath);
        console.log(`Success: ${outputPath}`);
    } catch (e) {
        console.error(`Error processing ${inputPath}: ${e.message}`);
    }
}

const images = [
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/scrap_bot_green_1772828344936.png', out: './assets/sprites/scrap_bot.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/turret_droid_green_1772828358985.png', out: './assets/sprites/turret_droid.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/heavy_mech_green_1772828372690.png', out: './assets/sprites/heavy_mech.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/pulse_drone_green_1772828387331.png', out: './assets/sprites/pulse_drone.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/jump_bot_green_1772828402395.png', out: './assets/sprites/jump_bot.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/shield_bot_green_1772828417597.png', out: './assets/sprites/shield_bot.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/nanite_fly_green_1772828433780.png', out: './assets/sprites/nanite_fly.png' }
];

(async () => {
    for (const img of images) {
        await removeGreen(img.in, img.out);
    }
})();
