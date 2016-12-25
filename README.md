# Create phylogenetic trees by xelatex/tikz/forest.

## A picture is worth a thousand words

Two means more.

![template.png](example/template.png)

![template.trans.png](example/template.trans.png)

## Tex/pdf files from manually created tikz/forest files

[A forest file](forest/test.forest).

```text
[, label=Opisthokonta, dot
    [, tier=1
        [Nucleariida]
        [Fungi]
    ]
    [, label=Holozoa, dot
        [Filasterea]
        [Ichthosporea]
        [, tier=1
            [\color{red}{Animals}]
            [Choanoflagellata]
        ]
    ]
]
```

The folllowing command will create `forest/test.trans.tex`.

```bash
perl forest.pl forest/test.forest -t translation/translation.csv -a
```

Adding `-p` will also create `.pdf`.

![test.trans.png](example/test.trans.png)

## Starting from a newick tree

Get a newick file from UCSC

```bash
curl http://hgdownload.cse.ucsc.edu/goldenpath/hg38/multiz7way/hg38.7way.commonNames.nh \
    > tree/hg38.7way.commonNames.nh
```

Create `tree/hg38.7way.commonNames.forest` by

```bash
perl tree.pl tree/hg38.7way.commonNames.nh
```

Edit this file if needed, such as adding annotations for nodes and branches, adding comments or
adjusting colors.

Then create pdfs.

```bash
perl forest.pl tree/hg38.7way.commonNames.forest -r -p
```

Or in one line, will create [`output.pdf`](example/output.pdf) .

```bash
curl http://hgdownload.cse.ucsc.edu/goldenpath/hg38/multiz100way/hg38.100way.scientificNames.nh \
    | perl tree.pl stdin -o stdout \
    | perl forest.pl stdin -r -p
```

## Create common tree from NCBI

* On the homepage of [NCBI Taxonomy](http://www.ncbi.nlm.nih.gov/taxonomy), click the link of
  [Common Tree](http://www.ncbi.nlm.nih.gov/Taxonomy/CommonTree/wwwcmt.cgi).

* Create a local plain text file, paste all the scientific names of desired into it. Use `Browse...`
  and `Add from file:` buttons to upload the newly created file.

* Choose `phylip tree` then click the button of `Save as`.

* A file with default name `phyliptree.phy` created. Edit it with Dendroscope and export as a
  .newick file.

```bash
perl tree.pl tree/Oleaceae.newick
cp tree/Oleaceae.forest forest/
```

* Edit `forest/Oleaceae.forest` manually.

    * Replace tribe labels with chromosome numbers.

    * Replace tribe dots with bars.

    * Sort genera by names.

```bash
perl forest.pl forest/Oleaceae.forest -t translation/translation.csv -a -p
```

## Dependences

* LaTeX (I use MacTex 2015/2016)
* LaTeX utilities
    * XeLaTeX
    * latexmk
* LaTeX packages
    * xeCJK
    * Tikz
    * Forest
* Perl
* Perl modules
    * Path::Tiny
    * Bio::Phylo
