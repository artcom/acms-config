const childProcess = require("child_process")

module.exports = (...args) => childProcess.execFileSync("git", args).toString().trim()
