gulp       = require 'gulp'
server     = require 'gulp-develop-server' 

gulp.task 'server:start', ->
  server.listen path: 'src/application.coffee'

gulp.task 'server:restart', ->
  server.restart()

gulp.task 'watch', ['server:start'], ->
  gulp.watch ['./app/**/*.coffee'], ['server:restart']
