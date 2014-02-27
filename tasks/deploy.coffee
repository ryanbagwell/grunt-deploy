#
# * grunt-deploy
# * http://zhefeng.github.io/grunt-deploy/
# *
# * Copyright (c) 2013 Zhe Feng
# * Licensed under the MIT license.
#


Connection = require "../lib/connection"
Git = require '../lib/git'

moment = require "moment"
fs = require 'fs'
util = require 'util'

path = require 'path'
#nodegit = require 'nodegit'
shelljs = require 'shelljs'




module.exports = (grunt) ->

  jobs =

    setup: (options, done) ->

      connection = new Connection()

      connection.on 'ready', ->

        connection.doesPathExist(options.releasesPath).then (exists) ->
          if not exists
            return connection.mkDir(options.releasesPath)
        # .then (exists) ->
        #   return connection.doesPathExist(options.buildPath)
        # .then (exists) ->
        #   if exists
        #     return connection.rmDir(path.join(options.releasesPath, '_build'))
        # # .then ->
        # #   return connection.mkDir(path.join(options.releasesPath, '_build'))
        .fail (error) ->
          console.log error
          done()
        .fin ->
          done()

      connection.connect options.server


    launch: (options, done) ->

      git = new Git path.join(process.env['PWD'], '.git')
      gitRemote = git.getRemoteOrigin()
      head = git.getHeadCommit()

      connection = new Connection()

      connection.on 'ready', ->

        connection.doesPathExist(options.buildPath).then (exists) ->
          return connection.rmDir(options.buildPath) if exists
        .then ->
          return connection.mkDir(options.buildPath)
        .then ->
          return connection.gitClone gitRemote, options.buildPath
        .then ->
          return connection.gitReset(head, options.buildPath)
        .fail (error) ->
          console.log error
        .fin ->
          console.log 'Done.'
          done()

      connection.connect options.server














  validateJob = (jobName) ->
    validJobs = ['setup', 'launch',]

    return if jobName in validJobs

    grunt.fail.fatal util.format('Invalid job: %s. Choices are: %s', jobName, validJobs.join(', '))


  grunt.registerMultiTask "deploy", "deploys your code", ->

    done = @async()

    requestedJob = if @args[0] then @args[0] else 'launch'

    validateJob(requestedJob)

    defaultOptions =

      buildPath: path.join @options().releasesPath, '_build'

      preSetup: ->
      postSetup: ->
      preDeploy: ->
      postDeploy: ->

    options = @options(defaultOptions)

    jobs[requestedJob](options, done)

    return








    self = this
    done = self.async()
    timeStamp = moment().format "YYYYMMDDHHmmssSSS"
    options = self.options()
    connections = []

    options.buildPath = path.join(options.releasesPath, '_build')





    execSingleServer = (server, connection) ->

      exec = (cmd, showLog, done) ->

        deferred = q.defer()

        connection.exec cmd, (err, stream) ->

          result = null

          throw err  if err

          stream.on "data", (data, extended) ->
            result = data + ''
            console.log result

          stream.on "end", ->
            response = if done then done(result) else null
            deferred.resolve(response)

        return deferred.promise


      execCmds = (cmds, index, showLog, next) ->

        if not cmds or cmds.length <= index
          next and next()
        else
          exec cmds[index++], showLog, ->
            execCmds cmds, index, next
            return

        return






      execCmds options.cmds_before_deploy, 0, true, (prevResult) ->

        console.log "cmds before deploy executed"

        createFolder = "cd " + options.deploy_path + "/releases && mkdir " + timeStamp

        removeCurrent = "rm -rf " + options.deploy_path + "/current"

        setCurrent = "ln -s " + options.deploy_path + "/releases/" + timeStamp + " " + options.deploy_path + "/current"

        console.log "start deploy"

        exec createFolder + " && " + removeCurrent + " && " + setCurrent, false, ->
          sys = require("sys")
          execLocal = require("child_process").exec
          child = undefined
          child = execLocal("scp -r . " + server.username + "@" + server.host + ":" + options.deploy_path + "/releases/" + timeStamp, (error, stdout, stderr) ->
            console.log "end deploy"
            console.log "executing cmds after deploy"
            execCmds options.cmds_after_deploy, 0, true, ->
              console.log "cmds after deploy executed"
              connection.end()
              return

            return
          )
          return

        return

      return





    length = options.servers.length

    completed = 0

    checkCompleted = ->
      completed++
      done()  if completed >= length
      return

    # options.servers.forEach (server) ->
    #   c = new Connection()

    #   c.on "connect", ->
    #     console.log "Connecting to server: " + server.host
    #     return

    #   c.on "ready", ->
    #     console.log "Connected to server: " + server.host
    #     execSingleServer server, c
    #     return

    #   c.on "error", (err) ->
    #     console.log "Error on server: " + server.host
    #     console.error err
    #     throw err  if err
    #     return

    #   c.on "close", (had_error) ->
    #     console.log "Closed connection for server: " + server.host
    #     checkCompleted()
    #     return

    #   c.connect server
