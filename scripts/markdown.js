const showdown = require("showdown");
const replace = require("replace-in-file");
const fs = require("fs");
const Handlebars = require("handlebars");
const { squash, mapO } = require("./utils");

const converter = new showdown.Converter();

const contentFiles = fs.readdirSync("./content");
const htmlFiles = fs.readdirSync("./html");

const replacements = contentFiles.map((file) => {
  const spl = file.split(".");
  return {
    ext: spl[1],
    fileName: spl[0],
  };
});

const fileContents = replacements.map(({ fileName, ext }) => {
  return {
    fileName,
    ext,
    content: fs.readFileSync(`./content/${fileName}.${ext}`, "utf8"),
  };
});

const htmlContents = fileContents.map(({ fileName, ext, content }) => {
  return {
    [fileName]: ext === "md" ? converter.makeHtml(content) : content,
  };
});

const vars = squash(htmlContents);
const htmlTemplatesArray = htmlFiles.map((filename) => {
  return {
    [filename]: Handlebars.compile(
      fs.readFileSync(`./html/${filename}`, "utf8"),
    ),
  };
});
const htmlTemplates = squash(htmlTemplatesArray);
const generated = mapO(htmlTemplates)((template) => template(vars));
Object.keys(generated).forEach((filename) => {
  fs.writeFileSync(`./docs/${filename}`, generated[filename]);
});
