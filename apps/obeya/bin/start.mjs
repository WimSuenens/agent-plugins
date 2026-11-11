#!/usr/bin/env node
// Starts the built server. Refuses any non-loopback bind with one line and a non-zero exit.
// Inside the container the server binds 0.0.0.0 (OBEYA_IN_CONTAINER=1) and the host publishes the port on 127.0.0.1 only.
import { fileURLToPath } from 'node:url'

const host = process.env.OBEYA_HOST || '127.0.0.1'
const loopback = ['127.0.0.1', 'localhost', '::1'].includes(host) || /^127\.\d+\.\d+\.\d+$/.test(host)
const inContainer = process.env.OBEYA_IN_CONTAINER === '1' && host === '0.0.0.0'
if (!loopback && !inContainer) {
  console.error(`obeya: refusing to bind ${host}; only loopback addresses are allowed (127.0.0.1, localhost, ::1)`)
  process.exit(1)
}
process.env.NITRO_HOST = host
process.env.NITRO_PORT = process.env.OBEYA_PORT || process.env.NITRO_PORT || '3000'
process.env.NUXT_PUBLIC_BIND_ADDRESS = `${host}:${process.env.NITRO_PORT}`
if (process.env.OBEYA_REFRESH_SECONDS) process.env.NUXT_PUBLIC_REFRESH_SECONDS = process.env.OBEYA_REFRESH_SECONDS
await import(fileURLToPath(new URL('../.output/server/index.mjs', import.meta.url)))
