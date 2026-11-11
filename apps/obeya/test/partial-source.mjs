// A source where the project "bad" is listed fine but its item read fails, to prove one project's failure does not blank the others.
import stub from './stub-source.mjs'
export default {
  ...stub,
  async items(p) {
    if (p.id === 'bad') throw new Error('tracker unavailable for bad')
    return stub.items(p)
  },
}
