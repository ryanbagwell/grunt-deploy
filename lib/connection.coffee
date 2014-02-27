Ssh = require "ssh2"
util = require 'util'
Q = require 'q'


class Connection extends Ssh

      run: (cmd, log, done) ->

        deferred = Q.defer()

        console.log "Executing: #{cmd}" if log

        @exec cmd, (err, stream) ->

          result = null

          throw err  if err

          stream.on "data", (data, extended) ->
            result = data + ''

          stream.on "end", ->
            response = if done then done(result) else null
            deferred.resolve(response)

        return deferred.promise

      cd: (path) ->
        cmd = util.format 'cd %s', path
        return @run cmd, true

      doesPathExist: (path) ->
        cmd = util.format '[ -e %s ] && echo 1 || echo 0', path
        return @run cmd, true, (result) ->
          result = parseInt(result)
          return if result is 1 then true else false

      mkDir: (path) ->
        cmd = util.format 'mkdir -p ', path
        return @run cmd, true, (result) ->
          console.log "Created #{path}"

      rmDir: (path) ->
        cmd = util.format 'rm -rf ', path
        return @run cmd, true, (result) ->
          console.log "Removing #{path}"

      gitClone: (remotePath, path) ->
        cmd = util.format 'git clone %s %s', remotePath, path
        return @run cmd, true, (result) ->
          console.log "Cloned #{remotePath} to #{path}"

      gitReset: (sha, gitPath) ->
        cmd = util.format 'git --git-dir=%s reset --hard %s', gitPath, sha
        return @run cmd, true, (result) ->
          console.log "Reset HEAD to #{sha}"

module.exports = Connection