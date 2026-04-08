/** @type {import('next').NextConfig} */
const nextConfig = {
    // output: 'export', // Disabled for dev - enable only for production build
    trailingSlash: true,
    images: {
        unoptimized: true
    },
    // Optimize build performance
    swcMinify: true,
    reactStrictMode: true,
    // Disable resource hints to prevent preload warnings
    experimental: {
        optimizeCss: false,
    },
    webpack: (config, { isServer }) => {
        if (!isServer) {
            config.resolve.fallback = {
                ...config.resolve.fallback,
                fs: false,
                net: false,
                tls: false,
                crypto: false,
                stream: false,
                http: false,
                https: false,
                zlib: false,
                path: false,
                os: false,
            };
        }

        config.externals = config.externals || [];
        config.externals.push('undici');

        // Reduce chunk splitting to minimize preload warnings
        if (!isServer) {
            config.optimization = {
                ...config.optimization,
                splitChunks: {
                    chunks: 'all',
                    cacheGroups: {
                        default: false,
                        vendors: false,
                        commons: {
                            name: 'commons',
                            chunks: 'all',
                            minChunks: 2,
                        },
                    },
                },
            };
        }

        return config;
    },
};

module.exports = nextConfig;
