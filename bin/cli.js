#!/usr/bin/env node

const { execSync, spawn } = require("child_process");
const path = require("path");
const fs = require("fs");

const scriptPath = path.join(__dirname, "..", "install.sh");

// When run via npx, the package is in a temp cache dir.
// We need to pass the install.sh from the package, but run it in the user's cwd.
const args = process.argv.slice(2);

// Check if install.sh exists (local dev or npm package)
if (fs.existsSync(scriptPath)) {
  const child = spawn("bash", [scriptPath, ...args], {
    cwd: process.cwd(),
    stdio: "inherit",
  });
  child.on("exit", (code) => process.exit(code));
} else {
  // Fallback: download and run from GitHub
  const cmd = `curl -fsSL https://raw.githubusercontent.com/Neurons-AI/vibecodekit/main/install.sh | bash -s -- ${args.join(" ")}`;
  try {
    execSync(cmd, { cwd: process.cwd(), stdio: "inherit" });
  } catch (e) {
    process.exit(e.status || 1);
  }
}
