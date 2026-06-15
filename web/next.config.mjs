import nextra from 'nextra'

const withNextra = nextra({
  search: { codeblocks: false },
})

export default withNextra({
  images: { unoptimized: true },
  webpack: (config) => {
    const path = require('path')
    config.resolve.alias = {
      ...config.resolve.alias,
      'prism-coco': require.resolve('./lib/coco-prism.js'),
      'melange': path.resolve('./lib/coco/node_modules/melange'),
      'melange.js': path.resolve('./lib/coco/node_modules/melange.js'),
    }
    return config
  },
})
