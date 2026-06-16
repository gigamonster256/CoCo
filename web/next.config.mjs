import nextra from 'nextra'
import { createRequire } from 'node:module'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)
const melangeDir = resolve(__dirname, 'lib/coco/node_modules')

const aliases = {
  '@': __dirname,
  'melange': resolve(melangeDir, 'melange'),
  'melange.js': resolve(melangeDir, 'melange.js'),
}

const withNextra = nextra({
  search: { codeblocks: false },
})

export default withNextra({
  images: { unoptimized: true },
  webpack: (config) => {
    config.resolve.alias = { ...config.resolve.alias, ...aliases }
    return config
  },
  turbopack: {
    resolveAlias: aliases,
  },
})
