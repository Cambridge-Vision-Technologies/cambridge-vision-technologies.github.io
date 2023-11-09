# Our company website

[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)

## Aims

- responsive
- accessible
- simple

## Prerequisites

- You need to first create a `~/cvt-website.env` file in your home directory. This should contain all teh environment variables that are needed to build and deploy the system. A sample env file is included at [./sample.env](sample.env)

You should be able to develop and run this project directly in GitHub Codespaces or.

### Native

- NodeJS required, tested with node 18.18

### Docker

- VSCode can use docker to set up a local development environment for you

## Development

To run locally `make dev`

## Build

All commands are through make. See the [Makefile](Makefile) for details but some basic ones are `make build` and `make format`. If you run these commands on your native machine the makefiel will attempt to run them inside a docker container with all the dependencies needed. You can force them to run on your native machine by appending -local to the command e.g. `make build-local`.

## Technology

The site uses a simple fing-and-replace script to render the content markdown files and insert them into the html source files. Packaging of the generated html and css is done with parceljs. This also runs a dev server with hot reloading for fast development.

## Deployment

The website is deployed to github pages, for static sites. This is done with the cd process described in [.github/workflows/cd.yml](.github/workflows/cd.yml)

## Content

Content is contained in markdown files in `./content` here.

### Home

- [Welcome](content/welcome.md)

### Poblem

- [Alzheimers](content/alzheimers.md)
- [Challenge](content/challenge.md)

### Technology

- [Hardware](content/hardware.md)
- [AI](content/ai.md)
- [Platform](content/platform.md)

### About

- [About Us](content/us.md)
- [Contact](content/contact.md)
