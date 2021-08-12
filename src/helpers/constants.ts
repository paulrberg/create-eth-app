export const codeloadBaseUrl: string = "https://codeload.github.com";

export const Frameworks = ["react", "vue"] as const;
export type FrameworkKey = typeof Frameworks[number];

export const githubApiBaseUrl: string = "https://api.github.com/repos";

export const HandlebarsFiles: Record<FrameworkKey, string[]> = {
  react: [
    "package.json",
    "README.md",
    "packages/contracts/package.json",
    "packages/contracts/README.md",
    "packages/contracts/src/index.js",
    "packages/react-app/package.json",
    "packages/react-app/README.md",
    "packages/react-app/src/index.js",
    "packages/react-app/src/App.js",
  ],
  vue: [
    "package.json",
    "README.md",
    "packages/contracts/package.json",
    "packages/contracts/README.md",
    "packages/contracts/src/index.js",
    "packages/vue-app/package.json",
    "packages/vue-app/README.md",
    "packages/vue-app/src/main.js",
    "packages/vue-app/src/components/HelloWorld.vue",
  ],
};

// Hardcoded that are unique to each template.
export const HardcodedBespokeTemplateFiles: Record<FrameworkKey, string[]> = {
  react: [
    "packages/contracts/src/abis.js",
    "packages/contracts/src/addresses.js",
    "packages/contracts/src/abis",
    "packages/react-app/src/graphql/subgraph.js",
  ],
  vue: [
    "packages/contracts/src/abis.js",
    "packages/contracts/src/addresses.js",
    "packages/contracts/src/abis",
    "packages/vue-app/src/graphql/subgraph.js",
  ],
};

export const HardcodedTemplateFiles: Record<FrameworkKey, Record<TemplateKey, string[]>> = {
  react: {
    aave: HardcodedBespokeTemplateFiles.react,
    balancer: HardcodedBespokeTemplateFiles.react,
    chainlink: HardcodedBespokeTemplateFiles.react,
    compound: HardcodedBespokeTemplateFiles.react,
    default: [...HardcodedBespokeTemplateFiles.react, ".gitignore", "README.md", "packages/subgraph"],
    kyber: HardcodedBespokeTemplateFiles.react,
    maker: HardcodedBespokeTemplateFiles.react,
    mstable: HardcodedBespokeTemplateFiles.react,
    "sablier-v1": HardcodedBespokeTemplateFiles.react,
    synthetix: HardcodedBespokeTemplateFiles.react,
    "uniswap-v1": HardcodedBespokeTemplateFiles.react,
    "uniswap-v2": HardcodedBespokeTemplateFiles.react,
  },
  vue: {
    aave: HardcodedBespokeTemplateFiles.vue,
    balancer: HardcodedBespokeTemplateFiles.vue,
    chainlink: HardcodedBespokeTemplateFiles.vue,
    compound: HardcodedBespokeTemplateFiles.vue,
    default: [...HardcodedBespokeTemplateFiles.vue, ".gitignore", "README.md", "packages/subgraph"],
    kyber: HardcodedBespokeTemplateFiles.vue,
    maker: HardcodedBespokeTemplateFiles.vue,
    mstable: HardcodedBespokeTemplateFiles.vue,
    "sablier-v1": HardcodedBespokeTemplateFiles.vue,
    synthetix: HardcodedBespokeTemplateFiles.vue,
    "uniswap-v1": HardcodedBespokeTemplateFiles.vue,
    "uniswap-v2": HardcodedBespokeTemplateFiles.vue,
  },
};

// https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
export const semanticVersionRegex: RegExp = /(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?/;

export const Templates = [
  "aave",
  "balancer",
  "chainlink",
  "compound",
  "default",
  "kyber",
  "maker",
  "mstable",
  "sablier-v1",
  "synthetix",
  "uniswap-v1",
  "uniswap-v2",
] as const;
export type TemplateKey = typeof Templates[number];
