// Packs project source files into dist/game.love (a zip containing main.lua at root).
const fs = require("fs");
const path = require("path");
const archiver = require("archiver");

const ROOT = path.resolve(__dirname, "..");
const OUT_DIR = path.join(ROOT, "dist");
const OUT_FILE = path.join(OUT_DIR, "game.love");

const INCLUDE = ["main.lua", "conf.lua", "src", "assets"];

fs.mkdirSync(OUT_DIR, { recursive: true });
if (fs.existsSync(OUT_FILE)) fs.unlinkSync(OUT_FILE);

const output = fs.createWriteStream(OUT_FILE);
const archive = archiver("zip", { zlib: { level: 9 } });

output.on("close", () => {
    console.log(`packed ${archive.pointer()} bytes -> ${path.relative(ROOT, OUT_FILE)}`);
});
archive.on("warning", (e) => { if (e.code !== "ENOENT") throw e; });
archive.on("error", (e) => { throw e; });

archive.pipe(output);
for (const entry of INCLUDE) {
    const full = path.join(ROOT, entry);
    if (!fs.existsSync(full)) continue;
    const stat = fs.statSync(full);
    if (stat.isDirectory()) archive.directory(full, entry);
    else archive.file(full, { name: entry });
}
archive.finalize();
