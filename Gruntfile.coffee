#
# * grunt-deploy
# * http://zhefeng.github.io/grunt-deploy/
# *
# * Copyright (c) 2013 Zhe Feng
# * Licensed under the MIT license.
#
"use strict"
module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig

    pkg: grunt.file.readJSON "package.json"

    jshint:
      all: [
        "Gruntfile.js"
        "tasks/*.js"
        "<%= nodeunit.tests %>"
      ]

      options:
        jshintrc: ".jshintrc"


    # Before generating any new files, remove any previously-created files.
    clean:
      tests: ["tmp"]


    # Configuration to be run (and then tested).
    deploy:
      liveservers:
        options:
          servers: require("servers").servers()
          cmds_before_deploy: []
          cmds_after_deploy: []
          deploy_path: "~/grunt-plugins/grunt-deploy"

    nodeunit:
      tests: ["test/*_test.js"]


  # Actually load this plugin's task(s).
  grunt.loadTasks "tasks"

  # These plugins provide necessary tasks.
  grunt.loadNpmTasks "grunt-contrib-jshint"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-nodeunit"
  grunt.registerTask "default", ["deploy"]
