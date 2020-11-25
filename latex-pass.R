.libPaths('~/R')

pp = readRDS('packages.rds')
p1 = pp[[1]]; p2 = pp[[2]]
one_string = function(..., s = ' ') paste(..., collapse = s)

msg = c(
  if (length(p1)) c('The missing packages identified from the LaTeX log are:\n\n    ', one_string(p1)),
  if (length(p2)) c('\n\nAdditional packages required to compile your documents are:\n\n    ', one_string(p2))
)
msg2 = if (length(msg)) {
  p = sort(unique(c(p1, p2)))
  c(
    sprintf(
      '\n\nIf you are an R user using TinyTeX, you may install these packages via:\n\n    tinytex::tlmgr_install(c(%s))',
      one_string(sprintf("'%s'", p), s = ', ')
    ),
    '\n\nIf you use TinyTeX, including LaTeX for Manim (https://chocolatey.org/packages/manim-latex), you may install these packages via command line:\n\n    tlmgr install ',
    one_string(p),
    '\n\nIf you do not use TinyTeX (https://yihui.org/tinytex/), you need to figure out how to install them by yourself.'
  )
} else {
  msg = 'I did not figure out which LaTeX packages you need to install. Sorry.'
  ""
}
message(msg, msg2)
writeLines(one_string(msg, s = ''), 'message.txt')
writeLines(one_string(msg2, s = ''), 'details.txt')
