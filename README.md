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
