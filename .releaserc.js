const fs = require('fs');
const path = require('path');

// Load our custom Handlebars template
const template = fs.readFileSync(path.resolve(__dirname, '.github/templates/release-template.hbs'), 'utf-8');

module.exports = {
  branches: ['main'],
  plugins: [
    '@semantic-release/commit-analyzer',
    ['@semantic-release/release-notes-generator', {
      preset: 'angular',
      writerOpts: {
        mainTemplate: template,
      }
    }],
    '@semantic-release/github'
  ]
};