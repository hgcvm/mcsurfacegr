#!/bin/bash

# source: http://giantdorks.org/alain/bash-and-awk-to-convert-delimited-data-csv-tsv-etc-to-html-tables/

usage()
{
cat < output

Script to produce HTML tables from delimited input. Delimiter can be specified
as an optional argument. If omitted, script defaults to comma.

Options:

  -d       Specify delimiter to look for, instead of comma.

  --head   Treat first line as header, enclosing in  and  tags.

  --foot   Treat last line as footer, enclosing in  and  tags. 

Examples:

  1. $(basename $0) input.csv

  Above will parse file 'input.csv' with comma as the field separator and
  output HTML tables to STDOUT.

  2. $(basename $0) -d '|' < input.psv > output.htm

  Above will parse file "input.psv", looking for the pipe character as the
  delimiter, then output results to "output.htm".

  3. $(basename $0) -d '\t' --head --foot < input.tsv > output.htm

  Above will parse file "input.tsv", looking for tab as the delimiter, then
  process first and last lines as header/footer \(that contain data labels\), then
  write output to "output.htm".

EOF
}

while true; do
  case "$1" in
    -d)
      shift
      d="$1"
      ;;
    --foot)
      foot="-v ftr=1"
      ;;
    --help)
      usage
      exit 0
      ;;
    --head)
      head="-v hdr=1"
      ;;
    -*)
      echo "ERROR: unknown option '$1'"
      echo "see '--help' for usage"
      exit 1
      ;;
    *)
      f=$1
      break
      ;;
  esac
  shift
done

if [ -z "$d" ]; then
  d=","
fi

if [ -z "$f" ]; then
  echo "ERROR: input file is required"
  echo "see '--help' for usage"
  exit 1
fi

if ! [ -f "$f" ]; then
  echo "ERROR: input file '$f' is not readable"
  exit 1
else
  data=$(sed '/^$/d' $f)
  last=$(wc -l <<< "$data")
fi

awk -F "$d" -v last=$last $head $foot '
  BEGIN {
    print "  "
  }       
  {
    gsub(//, "\\>")
    if(NR == 1 && hdr) {  
      printf "    \n"
    gsub(/&/, "\\>")    }
    if(NR == last && ftr) {  
      printf "    \n"
    }
    print "      "
    for(f = 1; f <= NF; f++)  {
      if((NR == 1 && hdr) || (NR == last && ftr)) {
        printf "        \n", $f
      }
      else printf "        \n", $f
    }     
    print "      "
    if(NR == 1 && hdr) {
      printf "    \n"
    }
    if(NR == last && ftr) {
      printf "    \n"
    }
  }       
  END {
    print "  
%s	%s
"
  }
' <<< "$data"
