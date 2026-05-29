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

// Strip love.js / Emscripten branding from the generated page.
{
    let html = fs.readFileSync(indexPath, "utf8");
    html = html.replace(/^\s*loadingContext\.fillText\("Powered By Emscripten\."[^\n]*\n/m, "");
    html = html.replace(/^\s*loadingContext\.fillText\("Powered By LÖVE\."[^\n]*\n/m, "");
    // Replace footer with a clean fullscreen-only line.
    html = html.replace(
        /<footer>[\s\S]*?<\/footer>/,
        '<footer>\n      <p><button onclick="goFullScreen();">Fullscreen</button></p>\n    </footer>'
    );
    fs.writeFileSync(indexPath, html);
}

// Copy favicon and inject a <link> into index.html so the browser stops 404ing.
const favSrc = path.join(ROOT, "assets", "favicon.svg");
if (fs.existsSync(favSrc)) {
    fs.copyFileSync(favSrc, path.join(OUT_DIR, "favicon.svg"));
    let html = fs.readFileSync(indexPath, "utf8");
    if (!html.includes("favicon.svg")) {
        const link = '<link rel="icon" type="image/svg+xml" href="favicon.svg">';
        if (html.includes("</head>")) {
            html = html.replace("</head>", "  " + link + "\n</head>");
        } else if (html.includes("<head>")) {
            html = html.replace("<head>", "<head>\n  " + link);
        }
        fs.writeFileSync(indexPath, html);
    }
}

console.log("web build ready at", OUT_DIR);
