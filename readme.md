# This repo is officially abandoned and should be removed

# Radio Badger blog

Build status: ![build status](https://travis-ci.org/redbadger/radiobadger.com.svg)

This blog is deployed to [radiobadger.com](http://radiobadger.com)

## How to publish new blogpost

* Clone the whole repo
* Create a new file under `src/documents/posts`. Follow the style of previous posts - add meta data to the top of the file containing `name`, `date` and `layout` fields
* Write a post using normal markdown syntax
* You can generate the site and see how everything looks like by running `npm install` and then `./generate/bin/generator`. Site will be under `/out` directory if everything goes well
* Push your changes to the master branch of the repo (or make a pull request)
* Once the post is merged into the master, TravisCI will pick the change, rebuild site and publish everything to the production
* You can obviously create new posts just by using GitHub UI

## Tech details

Under the hood there is Red Badger Generator located under `/generate`. It's a (you guessed it) static pages generator. Blazing fast and easy to use.

To generate site run these commands:

    npm install
    ./generate/bin/generator
