
const Jimp = require('jimp');

async function processImage(inputPath, outputPath) {
    try {
        console.log(`Starting: ${inputPath}`);
        const image = await Jimp.read(inputPath);

        // Remove white or near-white background
        // Image generation often results in #FFFFFF backgrounds
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
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/chaser_mainframe_raw_1772883735640.png', out: 'D:/isaac-godot/assets/enemy_chaser_mainframe.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/shooter_mainframe_raw_1772883750502.png', out: 'D:/isaac-godot/assets/enemy_shooter_mainframe.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/tank_mainframe_raw_1772883766620.png', out: 'D:/isaac-godot/assets/enemy_tank_mainframe.png' },
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/fly_mainframe_raw_1772883783675.png', out: 'D:/isaac-godot/assets/enemy_fly_mainframe.png' }
];

(async () => {
    for (const img of images) {
        await processImage(img.in, img.out);
    }
})();
