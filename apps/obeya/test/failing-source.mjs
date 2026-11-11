// A source whose parse-failure read breaks, to prove the page shows a failed refresh instead of hiding it.
import stub from './stub-source.mjs'
export default {
  ...stub,
  async parseFailures() {
    throw new Error('source unavailable')
  },
}
