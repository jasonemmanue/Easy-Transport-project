/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Image Docker minimale (Railway) : voir Dockerfile.
  output: "standalone",
  images: { remotePatterns: [{ protocol: "https", hostname: "**" }] },
};
export default nextConfig;
