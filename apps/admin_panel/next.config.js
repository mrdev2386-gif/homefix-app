/** @type {import('next').NextConfig} */
const nextConfig = {
    transpilePackages: [
        'firebase',
        '@firebase/functions',
        '@firebase/auth',
        '@firebase/firestore',
        '@firebase/storage',
        'undici'
    ],
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

        // Force Firebase Functions to use the browser build instead of Node.js ESM
        config.resolve.alias = {
            ...config.resolve.alias,
            '@firebase/functions': 'firebase/functions',
        };

        config.module.rules.push({
            test: /\.m?js$/,
            type: 'javascript/auto',
            resolve: {
                fullySpecified: false,
            },
        });
        return config;
    },
};

module.exports = nextConfig;
