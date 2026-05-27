// Runs pack-love, then invokes love.js to produce web-build/.
const { spawnSync } = require("child_process");
const path = require("path");
const fs = require("fs");

const ROOT = path.resolve(__dirname, "..");
const LOVE_FILE = path.join(ROOT, "dist", "game.love");
const OUT_DIR = path.join(ROOT, "web-build");

function run(cmd, args, opts = {}) {
    console.log(">", cmd, args.map(a => /\s/.test(a) ? `"${a}"` : a).join(" "));
    const r = spawnSync(cmd, args, { stdio: "inherit", shell: false, cwd: ROOT, ...opts });
    if (r.status !== 0) process.exit(r.status || 1);
}

run(process.execPath, [path.join(ROOT, "scripts", "pack-love.js")]);

if (fs.existsSync(OUT_DIR)) fs.rmSync(OUT_DIR, { recursive: true, force: true });

const loveJsBin = path.join(ROOT, "node_modules", "love.js", "index.js");
run(process.execPath, [
    loveJsBin,
    "-c",
    "-t", "Worm Dungeon",
    LOVE_FILE,
    OUT_DIR,
]);

// Vercel prefers index.html at the output root; love.js already places one there.
const indexPath = path.join(OUT_DIR, "index.html");
if (!fs.existsSync(indexPath)) {
    console.error("ERROR: love.js did not produce an index.html in", OUT_DIR);
    process.exit(1);
}
console.log("web build ready at", OUT_DIR);
