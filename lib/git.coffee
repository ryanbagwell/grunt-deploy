shelljs = require 'shelljs'
util = require 'util'
_ = require 'underscore'
_.str = require 'underscore.string'

module.exports = class Git

    constructor: (@repoPath) ->


    getRemoteOrigin: ->
        cmd = util.format 'git --git-dir=%s config --get remote.origin.url', @repoPath
        return @_exec(cmd)

    getCurrentBranchName: ->
        cmd = util.format 'git --git-dir=%s rev-parse --abbrev-ref HEAD', @repoPath
        return @_exec(cmd)

    getHeadCommit: ->
        cmd = util.format 'git --git-dir=%s rev-parse HEAD', @repoPath
        return @_exec(cmd)

    _exec: (cmd) ->
        result = shelljs.exec(cmd, slient:true).output
        return _.str.trim result

