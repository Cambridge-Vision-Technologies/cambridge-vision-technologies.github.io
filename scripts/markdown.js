const showdown = require("showdown")
const replace = require('replace-in-file')
const fs = require('fs')

const converter = new showdown.Converter()

const contentFiles = fs.readdirSync("./content")
const htmlFiles = fs.readdirSync("./html")
const copied = htmlFiles.map((fileName)=> { fs.copyFileSync(`./html/${fileName}`, `./docs/${fileName}`)})
const replacements = contentFiles.map((file)=> {return file.split(".")[0]})
const markdown = replacements.map((name)=> fs.readFileSync(`./content/${name}.md`, "utf8"))
const html = markdown.map((md)=> {return converter.makeHtml(md)})
const options = {files: './docs/*.html', from: replacements.map((name) => `{{${name}}}`), to: html}
const results = replace.sync(options);

console.log(results)