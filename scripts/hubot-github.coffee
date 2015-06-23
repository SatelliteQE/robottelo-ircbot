# Description:
#   Hubot Github help you interact with Github from your bot.
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_GITHUB_API_URL
#   HUBOT_GITHUB_IGNORE_USERS
#   HUBOT_GITHUB_REPO
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_USER
#
# Commands:
#   #<number> - link to Github issue #<number> for HUBOT_GITHUB_USER/HUBOT_GITHUB_REPO project
#   <repository>#<number> - link to Github issue #<number> for HUBOT_GITHUB_USER/<repository> project
#   <user>/<repository>#<number> - link to GitHub issue #<number> for <user>/<repository> project
#
# Notes:
#   Environment variables description:
#
#     * HUBOT_GITHUB_API_URL: the API URL, if not specified will default to
#       https://api.github.com. This configuration allows using the plugin for
#       Github Enterprise.
#     * HUBOT_GITHUB_IGNORE_USERS: a | separated list of users to ignore.
#       Example: github|travis-ci
#     * HUBOT_GITHUB_REPO: the repository that will be searched when just the
#       issue number is specified.
#     * HUBOT_GITHUB_TOKEN: a personal access token to authenticate API
#       requests.
#     * HUBOT_GITHUB_USER: the user or organization that will be searched when
#       specified the repository name and issue number.
#
# Author:
#   elyezer

module.exports = (robot) ->
  config =
    api_url: process.env.HUBOT_GITHUB_API_URL or 'https://api.github.com'
    ignore_users: process.env.HUBOT_GITHUB_IGNORE_USERS or 'github'
    repo: process.env.HUBOT_GITHUB_REPO
    token: process.env.HUBOT_GITHUB_TOKEN
    user: process.env.HUBOT_GITHUB_USER


  unless config.user?
      robot.logger.error "hubot-github included, but missing HUBOT_GITHUB_USER."
      return
  unless config.repo?
      robot.logger.error "hubot-github included, but missing HUBOT_GITHUB_REPO."
      return
  unless config.token?
      robot.logger.error "hubot-github included, but missing HUBOT_GITHUB_TOKEN."
      return


  robot.hear /(\S*)?#(\d+)/, (msg) ->
    return if msg.message.user.name.match(new RegExp(config.ignore_users, "gi"))

    issue_number = msg.match[2]
    if isNaN(issue_number)
      return

    if msg.match[1] != undefined
      parts = msg.match[1].split('/')
      switch parts.length
        when 1
          user = config.user
          repo = parts[0]
        when 2
          user = parts[0]
          repo = parts[1]
        else
          return
    else
      user = config.user
      repo = config.repo

    robot.http("#{config.api_url}/repos/#{user}/#{repo}/issues/#{issue_number}")
      .header('Accept', 'application/json')
      .header('Authorization', "token #{config.token}")
      .get() (err, res, body) ->
        if res.statusCode is 200
          data = JSON.parse(body)
          msg.send "Issue #{data.number}: #{data.title} #{data.html_url}"
        else
          msg.send "The issue ##{issue_number} was not found on #{user}/#{repo} repository"
