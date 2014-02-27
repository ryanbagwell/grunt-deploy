#
# * grunt-deploy
# * http://zhefeng.github.io/grunt-deploy/
# *
# * Copyright (c) 2013 Zhe Feng
# * Licensed under the MIT license.
#


Connection = require "../lib/connection"
Git = require '../lib/git'

Q = require 'q'
moment = require "moment"
util = require 'util'
path = require 'path'
_ = require 'underscore'


module.exports = (grunt) ->

  jobs =

    setup: (options, done) ->

      connection = new Connection()

      connection.on 'ready', ->

        connection.doesPathExist(options.releasesPath).then (exists) ->
          if not exists
            return connection.mkDir(options.releasesPath)
        .fail (error) ->
          console.log error
          done()
        .fin ->
          done()

      connection.connect options.server


    launch: (options, done) ->

      timeStamp = moment().format "YYYY-MM-DD-HH-mmssSSS"

      git = new Git path.join(process.env['PWD'], '.git')
      gitRemote = git.getRemoteOrigin()
      head = git.getHeadCommit()

      connection = new Connection()

      connection.on 'ready', ->

        connection.doesPathExist(options.buildPath).then (exists) ->
          connection.rmDir(options.buildPath) if exists
        .then ->
          connection.mkDir(options.buildPath)
        .then ->
          options.preLaunch(options, connection)
        .then ->
          connection.gitClone gitRemote, options.buildPath
        .then ->
          connection.gitReset(head, options.buildPath)
        .then ->
          options.postLaunch(options, connection)
        .then ->
          timeStamp = moment().format "YYYY-MM-DD-HH-mmssSSS"
          connection.mv options.buildPath,
            path.join(options.releasesPath, timeStamp)
        .then ->
          connection.rmDir path.join(options.releasesPath, 'current')
        .then ->
          connection.mkSymlink path.join(options.releasesPath, timeStamp),
            path.join(options.releasesPath, 'current')
        .fail (error) ->
          console.log error
        .fin ->
          console.log 'Done.'
          done()

      connection.connect options.server

    rollback: (options, done) ->
      grunt.fail.fatal 'not implemented'


  grunt.registerMultiTask "deploy", "deploys your code", ->

    done = @async()

    requestedJob = if @args[0] then @args[0] else 'launch'

    if requestedJob not in _.keys jobs
      grunt.fail.fatal util.format('Invalid job: %s. Choices are: %s', requestedJob, _.keys(jobs).join(', '))

    defaultOptions =

      buildPath: path.join @options().releasesPath, '_build'

      preSetup: ->
      postSetup: ->
        console.log 'Finished postSetup.'
      preLaunch: ->
        console.log 'Finished preLaunch.'

      postLaunch: ->
        console.log 'Finished postLaunch.'


    options = @options(defaultOptions)

    jobs[requestedJob](options, done)

    return

