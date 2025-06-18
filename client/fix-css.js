#!/usr/bin/env bun
// fix-css.js - Fix CSS file serving issues for TandemX

import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const colors = {
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
  reset: "\x1b[0m",
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function copyFile(source, destination) {
  try {
    if (existsSync(source)) {
      const content = readFileSync(source);
      writeFileSync(destination, content);
      log("green", `✅ Copied: ${source} → ${destination}`);
      return true;
    } else {
      log("red", `❌ Source file not found: ${source}`);
      return false;
    }
  } catch (err) {
    log("red", `❌ Error copying ${source}: ${err.message}`);
    return false;
  }
}

function ensureDirectory(dirPath) {
  if (!existsSync(dirPath)) {
    mkdirSync(dirPath, { recursive: true });
    log("yellow", `📁 Created directory: ${dirPath}`);
  }
}

function fixCSSIssues() {
  log("blue", "=== TandemX CSS Fix Script ===\n");
  
  const clientDir = __dirname;
  const cssDir = join(clientDir, "css");
  const publicDir = join(clientDir, "public");
  const assetsDir = join(clientDir, "assets");
  
  // Ensure public directory exists
  ensureDirectory(publicDir);
  
  log("yellow", "Copying CSS files to public directory...");
  
  // CSS files to copy
  const cssFiles = [
    { source: join(cssDir, "styles.css"), dest: join(publicDir, "styles.css") },
    { source: join(cssDir, "nav.css"), dest: join(publicDir, "nav.css") },
    { source: join(cssDir, "lustre-components.css"), dest: join(publicDir, "lustre-components.css") }
  ];
  
  let successCount = 0;
  
  for (const { source, dest } of cssFiles) {
    if (copyFile(source, dest)) {
      successCount++;
    }
  }
  
  // Check for existing styles.css in root
  const rootStyles = join(clientDir, "styles.css");
  if (existsSync(rootStyles)) {
    copyFile(rootStyles, join(publicDir, "root-styles.css"));
    successCount++;
  }
  
  // Create a combined CSS file for easier serving
  log("yellow", "\nCreating combined CSS file...");
  
  let combinedCSS = "/* TandemX Combined Styles */\n\n";
  
  for (const { dest } of cssFiles) {
    if (existsSync(dest)) {
      const filename = dest.split("/").pop();
      combinedCSS += `/* === ${filename} === */\n`;
      combinedCSS += readFileSync(dest, "utf-8");
      combinedCSS += "\n\n";
    }
  }
  
  // Add some basic fallback styles
  combinedCSS += `
/* === Fallback Styles === */
body {
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  margin: 0;
  padding: 0;
  line-height: 1.6;
  color: #333;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

/* Navigation fallback */
nav {
  background: #f8f9fa;
  padding: 1rem 0;
  border-bottom: 1px solid #dee2e6;
}

nav ul {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  gap: 2rem;
}

nav a {
  text-decoration: none;
  color: #495057;
  font-weight: 500;
}

nav a:hover {
  color: #007bff;
}

/* Button styles */
button {
  background: #007bff;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

button:hover {
  background: #0056b3;
}

/* Form styles */
input, textarea, select {
  border: 1px solid #ced4da;
  border-radius: 4px;
  padding: 0.5rem;
  font-size: 14px;
}

input:focus, textarea:focus, select:focus {
  border-color: #007bff;
  outline: none;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

/* Utility classes */
.text-center { text-align: center; }
.mb-3 { margin-bottom: 1rem; }
.mt-3 { margin-top: 1rem; }
.p-3 { padding: 1rem; }
.border { border: 1px solid #dee2e6; }
.rounded { border-radius: 4px; }

/* Loading indicator */
.loading {
  opacity: 0.6;
  pointer-events: none;
}

.loading::after {
  content: " ⏳";
}
`;
  
  writeFileSync(join(publicDir, "combined.css"), combinedCSS);
  log("green", "✅ Created combined.css");
  
  // Update index.html to include fallback CSS loading
  const indexPath = join(clientDir, "index.html");
  if (existsSync(indexPath)) {
    let indexContent = readFileSync(indexPath, "utf-8");
    
    // Add fallback CSS link if not present
    if (!indexContent.includes("combined.css")) {
      const cssLinksRegex = /(<link[^>]*stylesheet[^>]*>)/gi;
      const fallbackLink = '\n        <link rel="stylesheet" href="/combined.css" onerror="console.warn(\'Fallback CSS loaded\')">';
      
      if (cssLinksRegex.test(indexContent)) {
        indexContent = indexContent.replace(cssLinksRegex, (match) => match + fallbackLink);
      } else {
        // Add before closing head tag
        indexContent = indexContent.replace("</head>", `        <link rel="stylesheet" href="/combined.css">\n    </head>`);
      }
      
      writeFileSync(indexPath, indexContent);
      log("green", "✅ Updated index.html with fallback CSS");
    }
  }
  
  // Create CSS serving test file
  const testCSS = `
/* CSS Test File */
.css-test {
  background: #d4edda;
  color: #155724;
  padding: 10px;
  border: 1px solid #c3e6cb;
  border-radius: 4px;
  margin: 10px 0;
}

.css-test::before {
  content: "✅ CSS is loading correctly! ";
  font-weight: bold;
}
`;
  
  writeFileSync(join(publicDir, "test.css"), testCSS);
  log("green", "✅ Created test.css for debugging");
  
  // Summary
  log("blue", `\n=== Summary ===`);
  log("green", `✅ ${successCount} CSS files processed`);
  log("green", `✅ Combined CSS file created`);
  log("green", `✅ Test CSS file created`);
  
  log("yellow", "\nTo test CSS loading:");
  log("blue", "1. Start your server: bun start");
  log("blue", "2. Open browser to: http://localhost:8000");
  log("blue", "3. Check browser console for CSS loading errors");
  log("blue", "4. Test individual CSS files:");
  log("blue", "   - http://localhost:8000/css/styles.css");
  log("blue", "   - http://localhost:8000/combined.css");
  log("blue", "   - http://localhost:8000/test.css");
  
  log("green", "\n🎉 CSS fix complete!");
}

// Run the fix
try {
  fixCSSIssues();
} catch (err) {
  log("red", `❌ Error running CSS fix: ${err.message}`);
  console.error(err);
  process.exit(1);
}