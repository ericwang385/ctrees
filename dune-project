(lang dune 3.7)
(using coq 0.7)
(name coq-ctree)

(license "GPLv3")
(authors "Nicolas Chappe" "Paul He" "Ludovic Henrio" "Yannick Zakowski" "Steve Zdancewic")
(maintainers "Yannick Zakowski")
(source (github vellvm/ctrees))
(bug_reports "https://github.com/vellvm/ctrees/issues")

(generate_opam_files true)

(package
 (name coq-ctree)
 (synopsis "Library for representing recursive, non-deterministic and impure programs with equational reasoning")
 (version 0.1)
 (depends
  (coq (>= 8.17))
  (coq-ext-lib (>= 0.11.8))
  (coq-coinduction (>= 1.6))
  (coq-relation-algebra (>= 1.7))
  (coq-equations (>= 1.3))
  (coq-itree (>= 5.0)))
)
