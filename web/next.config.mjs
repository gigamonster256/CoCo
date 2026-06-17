import nextra from "nextra";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const aliases = {
  "@": __dirname,
};

const withNextra = nextra({
  search: { codeblocks: false },
});

export default withNextra({
  images: { unoptimized: true },
  webpack: (config) => {
    config.resolve.alias = { ...config.resolve.alias, ...aliases };
    return config;
  },
  turbopack: {
    resolveAlias: aliases,
  },
});
