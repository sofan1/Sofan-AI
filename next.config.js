export default {
  serverExternalPackages: [],
  // No rewrites — middleware (proxy.ts) rewrites everything to /api/proxy/*.
  // Instrumentation hook (instrumentation.ts) is enabled by default in Next.js 16.
  async rewrites() {
    return [];
  },
};
