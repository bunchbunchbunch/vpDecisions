const { getDefaultConfig } = require('expo/metro-config');

module.exports = (() => {
  const config = getDefaultConfig(__dirname);

  // Keep SVG as an asset extension (default behavior)
  // This allows using SVG files as Image sources rather than React components
  // which provides proper isolation and avoids ID conflicts

  return config;
})();
