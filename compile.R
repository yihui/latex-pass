# install TinyTeX
install.packages('xfun')
xfun::pkg_load2('tinytex')
tinytex::install_tinytex()

p0 = tinytex::tl_pkgs()  # the initial set of LaTeX packages installed
p1 = NULL  # missing packages identified from the LaTeX log

# parse LaTeX errors from .log files, or compile .Rmd/.tex files to figure out
# missing LaTeX packages
for (f in list.files('.', '[.](Rmd|tex|log)$')) {
  # different actions according to filenames extensions
  switch(
    xfun::file_ext(f),
    Rmd = if (length(grep('^---\\s*$', readLines(f, n = 1)))) {
      # the first line needs to be ---, in case it's a child Rmd file
      xfun::pkg_load2('rmarkdown')
      # make sure pandoc and pandoc-citeproc are installed
      for (i in c('pandoc', 'pandoc-citeproc')) {
        if (Sys.which(i) == 0) system(paste('brew install', i))
      }
      rmarkdown::render(f)
    },
    tex = if (length(grep('\\\\(documentclass|begin\\{document\\})', readLines(f))) >= 2) {
      # need to find \documentclass or \begin{document} in the .tex file
      r = '.*?((?:pdf|xe|lua)?latex).*'
      engine = if (length(grep(r, f))) gsub(r, '\\1', f) else 'pdflatex'
      r = '.*?(bibtex|biber).*'
      bib_engine = if (length(grep(r, f))) gsub(r, '\\1', f) else 'bibtex'
      tinytex::latexmk(f, engine = engine, bib_engine = bib_engine)
    },
    log = {
      p1 = c(p1, tinytex::parse_packages(f))
    }
  )
}
p2 = setdiff(tinytex::tl_pkgs(), p0)  # newly installed packages after compiling Rmd/tex files
saveRDS(list(p1, p2), file = 'packages.rds')
