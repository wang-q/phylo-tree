# Create phylogenetics trees by xelatex/tikz/forest.

## Manually create tikz/forest files

```bash
perl forest.pl forest/test.forest -t forest/translation.csv
```

will create `forest/test.trans.tex`.

Add `--pdf` or `-p` will create `.tex` and `.pdf`.

## Convert newick to tikz/forest file

```bash
perl tree.pl tree/hg38.7way.commonNames.nh
```

will create `tree/hg38.7way.commonNames.forest`. Edit this file if needed.

Then create pdfs.

```bash
perl forest.pl tree/hg38.7way.commonNames.forest -r -p
```

## Create common tree from NCBI

* On the homepage of [NCBI Taxonomy](http://www.ncbi.nlm.nih.gov/taxonomy), click the link of
[Common Tree](http://www.ncbi.nlm.nih.gov/Taxonomy/CommonTree/wwwcmt.cgi).

* Create a local plain text file, paste all the scientific names of desired into it. Use `Browse...` and `Add from file:` buttons to upload the newly created file.

* Choose `phylip tree` then click the button of `Save as`.

* A file with default name `phyliptree.phy` created.

## Dependences

* LaTeX
* LaTeX packages
    * XeLaTeX
    * xeCJK
    * Tikz
    * Forest
* Perl
* Perl modules
    * Path::Tiny
    * Bio::Phylo
