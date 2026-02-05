/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'export',
    images: {
        unoptimized: true
    },
    transpilePackages: ['undici', 'firebase'],
    webpack: (config) => {
        config.resolve.alias = {
            ...config.resolve.alias,
            'undici': false,
        };
        return config;
    },
};

module.exports = nextConfig;
