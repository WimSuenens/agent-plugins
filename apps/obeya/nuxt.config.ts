export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  ssr: true,
  devtools: { enabled: false },
  telemetry: false,
  // bin/start.mjs sets NUXT_PUBLIC_BIND_ADDRESS and NUXT_PUBLIC_REFRESH_SECONDS (from OBEYA_REFRESH_SECONDS) at run time.
  runtimeConfig: {
    public: {
      bindAddress: '',
      refreshSeconds: 15,
    },
  },
})
