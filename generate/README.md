generator
=========

Extremely simple and flexible static site generator

## Why

Because it's really simple. The generator has few opinions on how a static
site should be built. It suggest a default file layout and naming, but that's as
far as it will go. Because it's really simple, it's really fast and efficient.
And because of the way the configuration is handled (see below) it's extremely
flexible.

You can easily use it to write a personal blog, a product page, project
pages for your tool or a huge data driven site. As long as it doesn't change
too often, it can be a generated static site.

## Usage

Simply run

```
generate
```

to use the default settings. Generator will read your documents files from `src/documents`
wrap them in layouts from `src/layouts` add static files from `src/files` and
write your ready site into `out`.

You can override all these paths. Run

```
generate --help
```

for more more details

### Processing

Documents using the naming convention `file_name.output.input` will get converted from their
`input` format (e.g. jade) to their output format (e.g. html). Currently only
`jade`, `md`, `less` and `coffee` formats are supported. A plugin API for extending
this list will be added.

### Front-matter

All documents can have a yaml front-matter:

```
---
title: Example document
author: John Doe
tags: some, words, describing, document
date: 2014/05/01
layout: blog.jade
---
# Example document in markdown

The metadata above will be available for processing but not rendered into the
final output
```

### Configuration

The power of the generator is in it's configuration file. It's a javascript
file exporting two functions: `prepare` and `globals`.

`prepare` receives a list of all files which will be processed and returns a
new list of files. This gives it the ability to modify the list in **any**
way - add or remove documents, modify documents' front matter or even content.
For example, you can dynamically generate all the different index pages for your
blog as part of `prepare`.

`globals` receives the full list of documents as returned by `prepare` and
should return an object with all the global variables available to all template
files (layouts, for example) in the project. This is allows you to collect
data from the documents, process them and return them indexed or preprocessed in
a renderable form for output in more dynamic documents. The documents are compiled
*after* this stage and all keys in the returned object are available as variables
in them.
