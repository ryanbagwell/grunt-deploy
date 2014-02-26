#
# * grunt-deploy
# * http://zhefeng.github.io/grunt-deploy/
# *
# * Copyright (c) 2013 Zhe Feng
# * Licensed under the MIT license.
#


Connection = require "ssh2"
moment = require "moment"

module.exports = (grunt) ->

  grunt.registerMultiTask "deploy", "Your task description goes here.", ->
    self = this
    done = self.async()
    timeStamp = moment().format "YYYYMMDDHHmmssSSS"
    options = self.options()

    connections = []
    execSingleServer = (server, connection) ->
      exec = (cmd, showLog, next) ->

        #console.log(server.username + "@" + server.host + ":~$ " + cmd);
        connection.exec cmd, (err, stream) ->
          throw err  if err
          stream.on "data", (data, extended) ->
            showLog and console.log(data + "")
            return

          stream.on "end", ->
            next and next()
            return

          return

        return

      execCmds = (cmds, index, showLog, next) ->
        if not cmds or cmds.length <= index
          next and next()
        else
          exec cmds[index++], showLog, ->
            execCmds cmds, index, next
            return

        return

      console.log "executing cmds before deploy"
      execCmds options.cmds_before_deploy, 0, true, ->
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

    options.servers.forEach (server) ->
      c = new Connection()
      c.on "connect", ->
        console.log "Connecting to server: " + server.host
        return

      c.on "ready", ->
        console.log "Connected to server: " + server.host
        execSingleServer server, c
        return

      c.on "error", (err) ->
        console.log "Error on server: " + server.host
        console.error err
        throw err  if err
        return

      c.on "close", (had_error) ->
        console.log "Closed connection for server: " + server.host
        checkCompleted()
        return

      c.connect server
      return

    return

  return