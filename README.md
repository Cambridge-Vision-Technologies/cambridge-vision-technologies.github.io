# Our company website

## Prerequisites

You should be able to develop and run this project directly in GitHub Codespaces or.

### Native

- NodeJS required, tested with node 18.18

### Docker

- VSCode can use docker to set up a local development environment for you

## Development

To run locally `make dev`

## Technology

Teh site is currently just static html pages. We will probably move to Jekyll when we need to update it regularly.

## Deployment

The website is deployed to github pages, for static sites. This is done with the cd process described in `./.github/workflows/cd.yml`

## Content

Currently the content is static. But eventually will be contained in markdown files in `src` here.

- [index](content/index)
- [problem](content/problem)
- [technology](content/technology)
- [about](content/about)
