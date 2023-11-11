module.exports = {
  branches: ["main", { name: "staging", prerelease: true }, { name: "debugci", prerelease: true }, { name: "8", prerelease: true }],
  plugins: [
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "eslint",
        releaseRules: [
          { tag: "Docs", release: "patch" },
          { tag: "Build", release: "patch" },
          { tag: "Upgrade", release: "patch" },
          { tag: "Chore", release: "patch" },
        ],
      },
    ],
    [
      "@semantic-release/release-notes-generator",
      {
        preset: "eslint",
      },
    ],
    [
      "@semantic-release/changelog",
      {
        changelogFile: "CHANGELOG.md",
      },
    ],
    [
      "@semantic-release/github",
      {
        assets: [
          { path: "dist/**", label: "Website" },
          { path: "CHANGELOG.md", label: "Changelog" },
        ],
      },
    ],
    ["@semantic-release/npm"],
    [
      "@semantic-release/exec",
      {
        prepare: "make version VERSION=${nextRelease.version}",
      },
    ],
  ],
};
