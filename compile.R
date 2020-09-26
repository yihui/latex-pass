options(repos = "https://cran.rstudio.com")
dir.create('~/R', showWarnings = FALSE)
.libPaths('~/R')

# install xfun and tinytex
pkg_install = function(...) install.packages(..., quiet = TRUE)
pkg_install('xfun')
options(xfun.install.package = pkg_install)
xfun::pkg_load2(c('tinytex', 'rmarkdown'))

# install TinyTeX
suppressMessages(suppressWarnings(if (!tinytex:::is_tinytex()) tinytex::install_tinytex()))

p0 = tinytex::tl_pkgs()  # the initial set of LaTeX packages installed
p1 = NULL  # missing packages identified from the LaTeX log

# parse LaTeX errors from .log files, or compile .Rmd/.tex files to figure out
# missing LaTeX packages
for (f in list.files('.', '[.](Rmd|tex|log)$')) {
  if (!file.exists(f)) next  # the file might have been deleted
  # different actions according to filenames extensions
  switch(
    xfun::file_ext(f),
    Rmd = if (length(grep('^---\\s*$', readLines(f, n = 1)))) {
      # the first line needs to be ---, in case it's a child Rmd file
      xfun::pkg_load2('rmarkdown')
      # make sure pandoc and pandoc-citeproc are installed
      for (i in c('pandoc', 'pandoc-citeproc')) {
        if (Sys.which(i) == '') system(paste('brew install', i))
      }
      rmarkdown::render(f)
    },
    tex = {
      x = xfun::read_utf8(f)
      # need to find \documentclass or \begin{document} in the .tex file
      if (length(grep('\\\\documentclass', x)) == 0) next
      n1 = length(i1 <- grep('\\\\begin\\{document\\}', x))
      n2 = length(i2 <- grep('\\\\end\\{document\\}', x))
      if (n1 * n2 == 0) next
      if (n1 > 1 || n2 > 1) {
        warning('More than one line of code contains \\begin{document} or \\end{document}')
        next
      }
      # clear the document body, because it may have references to files that
      # users forgot or didn't want to upload to this repo; this approach won't
      # work for bibliography, but users can upload their LaTeX log in this case
      xfun::write_utf8(c(x[1:i1], 'Hello world!', x[i2]), f)
      r = '.*?((?:pdf|xe|lua)latex).*'
      engine = if (length(grep(r, f))) gsub(r, '\\1', f)
      # also try to infer engine from the comment like "% !TeX program = xelatex"
      r = '^(?:% !TeX program\\s*=\\s*)([[:alnum:]-]+).*'
      if (length(i <- grep(r, x))) engine = gsub(r, '\\1', x[i][1])
      # if I can't infer the engine, use pdflatex by default
      if (is.null(engine)) engine = 'pdflatex'
      r = '.*?(bibtex|biber).*'
      bib_engine = if (length(grep(r, f))) gsub(r, '\\1', f)
      if (is.null(bib_engine)) bib_engine = 'bibtex'
      tinytex::latexmk(f, engine = engine, bib_engine = bib_engine)
    },
    log = {
      if (file.size(f) == 0) next
      p1 = c(p1, tinytex::parse_packages(f))
    }
  )
}
p2 = setdiff(tinytex::tl_pkgs(), p0)  # newly installed packages after compiling Rmd/tex files
saveRDS(list(p1, p2), file = 'packages.rds')
