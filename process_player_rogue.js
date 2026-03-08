
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
    { in: 'C:/Users/home/.gemini/antigravity/brain/d3de2b6e-9ba7-4789-bf72-c5e4b1cd7de4/player_rogue_instance_raw_1772883997425.png', out: 'D:/isaac-godot/assets/player_rogue_instance.png' }
];

(async () => {
    for (const img of images) {
        await processImage(img.in, img.out);
    }
})();
