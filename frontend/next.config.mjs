/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Prevent webpack from bundling Node.js native modules used by stellar-sdk's
  // server-side signing path (sodium-native). These are irrelevant in the browser
  // and cause "Critical dependency" warnings during dev compilation.
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        crypto: false,
      };
    }
    // Silence sodium-native dynamic-require warnings
    config.externals = [
      ...(Array.isArray(config.externals) ? config.externals : [config.externals].filter(Boolean)),
      ({ request }, callback) => {
        if (request === 'sodium-native' || request === 'require-addon') {
          return callback(null, 'commonjs ' + request);
        }
        callback();
      },
    ];
    return config;
  },
};

export default nextConfig;
