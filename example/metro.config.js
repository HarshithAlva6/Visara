const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
const packageRoot = path.resolve(projectRoot, '..');

const config = getDefaultConfig(projectRoot);

config.watchFolders = [packageRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(packageRoot, 'node_modules'),
];

// Explicitly resolve @visara/core to the compiled bridge file,
// bypassing Metro's broken symlink resolution.
config.resolver.resolveRequest = (context, moduleName, platform) => {
  if (moduleName === '@visara/core') {
    return {
      filePath: path.resolve(packageRoot, 'bridge', 'index.js'),
      type: 'sourceFile',
    };
  }
  return context.resolveRequest(context, moduleName, platform);
};

module.exports = config;
