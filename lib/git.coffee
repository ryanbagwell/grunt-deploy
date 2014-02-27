shelljs = require 'shelljs'
util = require 'util'
_ = require 'underscore'
_.str = require 'underscore.string'

module.exports = class Git

    constructor: (@repoPath) ->


    getRemoteOrigin: ->
        cmd = util.format 'git --git-dir=%s config --get remote.origin.url', @repoPath
        @_exec(cmd)

    getCurrentBranchName: ->
        cmd = util.format 'git --git-dir=%s rev-parse --abbrev-ref HEAD', @repoPath
        @_exec(cmd)

    getHeadCommit: ->
        cmd = util.format 'git --git-dir=%s rev-parse HEAD', @repoPath
        @_exec(cmd)

    _exec: (cmd) ->
        result = shelljs.exec(cmd, silent:true).output
        _.str.trim result

