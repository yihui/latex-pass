.libPaths('~/R')

pp = readRDS('packages.rds')
p1 = pp[[1]]; p2 = pp[[2]]

msg = c(
  if (length(p1)) c('The missing packages identified from the LaTeX log are:\n\n    ', p1),
  if (length(p2)) c('\n\nAdditional packages required to compile your documents are:\n\n    ', p2)
)
msg = if (length(msg)) {
  p = sort(unique(c(p1, p2)))
  c(
    msg,
    sprintf(
      '\n\nIf you are an R user using TinyTeX, you may install these packages via:\n\n    tinytex::tlmgr_install(c(%s))',
      paste0('"', p, '"', collapse = ', ')
    ),
    '\n\nIf you use TinyTeX but are not an R user, you may install these packages via command line:\n\n    tlmgr install ',
    paste(p, collapse = ' '),
    '\n\nIf you do not use TinyTeX (https://yihui.org/tinytex/), you need to figure out how to install them by yourself.'
  )
} else {
  'I did not figure out which LaTeX packages you need to install. Sorry.'
}
message(msg)

json_str = function(x) {
  x = gsub('"', '\\\\"', x)
  x = gsub('\n', '\\\\n', x)
  x
}
# add a comment on the PR
if (Sys.getenv('APPVEYOR_PULL_REQUEST_NUMBER') != '') system2('curl', c(
  '-X', 'POST', '${APPVEYOR_API_URL}api/build/messages', '-d', shQuote(sprintf(
    '{"message": "%s", "category": "information", "details": ""}', json_str(paste(msg, collapse = ''))
  ))
))
