# BlackboardTool

Helps you evaluating blackboard submissions

## bb\_extract.sh

```text
bb_extract.sh [options] <zip> <target>

Options:
    -f, --force                force overwrite of target directory
    -h, --help                 this help page
``` 

Takes a ZIP file with all submissions downloaded from Blackboard and extracts it to the following structure:
```
<target>/<student-username>/
    raw (raw files of submission)
    doc (document files like pdfs and txts)
    src (src files either directly submitted or extracted from attached archives)
```

It supports different archiving formats like zip, tgz, rar... and uses tools like 7zip, unrar and unzip to extract them. Document file extensions and Source file extensions are setup at the beginning of that script and decide which files are sorted to where. It only extracts the first archive into the src directory.

## bb\_repair.sh

```text
bb_repair.sh [options] <folder> <rapair-template>

Options:
    -h, --help                 this help page
```

Can be applied on an extracted folder from bb\_extract.sh and uses an template to repair the source files from a submission. The repair template is a folder containing a file called 'repair. That file contains rules which are applied in order on the students src folder.

```
D *.bmp
D *.o
R main.c
S files
```

The 'D' rule deletes the files that match this pattern. The 'R' rule requires the specified file or folder and stops if it doesn't exist. The 'S' rule applies a folder structure for repair, which creates and copies files from that folder to the students src folder if they are non existent.


## bb\_symbols.sh

```text
bb_symbols.sh [options] <folder>

Options:
    -c, --counters  counter file
    -h, --help      this help page
```
This tool takes a counter file in which each line represents a symbol that is going to be counted in the src folder. It then counts each symbol for each students src folder (be aware that binary files can also include that symbol, thus should be cleaned up before using bb\_repair.sh). At the end it compares all counters of every student and ouputs those who have the same symbol count. This helps finding plagiarism by counting common symbols. It also gives you a nice and short summary of which symbols the student used.

## bb\_evaluate.sh

```text
bb_evaluate.sh [options] <folder> [students...]

Options:
    -q, --quiet                no interactive questions
    -f, --force                (re)evaluate all
    -s, --script <script>      use evaluation script
    -r, --ressource            pass ressource directory to script
    -h, --help                 this help page
```

This script goes through every student in the extracted folder, outputs the submission details, counted symbols (if available) and optionally executes an evaluation script on this student. As every assignment is different, there can't be one evaluation script for all. As every student should be after extraction and repair in a standarized format it should be fairly easy to write a general evaluation script for each assignment. The script is called with 2 parameters. The first one is the directory of the student that is currently evaluated and the second one is a ressource folder which can be passed also to bb\_evaluate.sh. The ressource folder is supposed to hold input and output data sets for the assignment to check the student against. The script executes assignment specific tasks like compiling and executing the application of the student. All outputs by the script are displayed and saved to an eval.log in the student directory. If no students are specified to be evaluated, all are going to be evaluated if they don't have an eval.log file or the file contains the word error, failed or timeout (case insensitive). The force option forces an reevaluation on the given students.
