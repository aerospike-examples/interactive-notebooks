#!/bin/bash

OUTPUT_FILE="./README.md"

#### Constant header text ####
HEADER_TEXT=$( cat <<"END-HEADER-TEXT"
# Notebooks

This area is for [Jupyter notebooks](https://jupyter.org/) in .ipynb format. Python and Java notebooks are currently supported by the kernel. 

The list of notebooks below has links to browse each notebook in the viewer and to launch it in interactive mode in Binder. This repository also provides a Docker container that you can install (see the [instructions](../README.md)) to run the notebooks locally. 
END-HEADER-TEXT
)

#### Constant footer text ####
FOOTER_TEXT=$( cat <<"END-FOOTER-TEXT"

_Copyright Aerospike Inc 2021_
END-FOOTER-TEXT
)

REPO="aerospike/aerospike-dev-notebooks.docker"
REPO_URL="https://github.com/${REPO}"
VIEWER_URL="${REPO_URL}/tree/main/notebooks"
BINDER_URL="https://mybinder.org/v2/gh/aerospike/aerospike-dev-notebooks.docker/main?filepath="

function get_title () {
  fname=$1

  nice_name=$( grep -m1 '^ *"# ' $fname | sed -e 's/^ *"# //' -e 's/\\n",$//' -e 's/\\"/"/g' )
  if [[ $nice_name ]] ; then
    echo $nice_name
  else
    echo $fname
  fi
}

function get_notebooks () {
  dir=$1

  for ii in ${dir}/*.ipynb ; do
    echo ${ii} | sed -e 's/^\.\///'
  done
}

function print_notebooks_table () {
  title=$1
  notebooks=$2

  echo ""
  echo "${title} | View | Launch"
  echo "-------- | ---- | ------"

  for ii in $notebooks ; do
    view_url="${VIEWER_URL}/${ii}"
    launch_url="${BINDER_URL}${ii}"
    nice_name=$( get_title $ii )

    echo "${nice_name} | [View](${view_url}) | [Launch](${launch_url})"
  done

  echo ""
}

function print_notebook_rows () {
  notebooks=$1

  for ii in $notebooks ; do
    view_url="${VIEWER_URL}/${ii}"
    launch_url="${BINDER_URL}${ii}"
    nice_name=$( get_title $ii )

    echo "&nbsp; ${nice_name} | [View](${view_url}) | [Launch](${launch_url})"
  done
}

#### Main

# check whether we're in the right repo's notebooks directory
if [[ ! $PWD =~ aerospike-dev-notebooks.docker/notebooks$ ]] ; then
  echo 'Must cd to the "notebooks" directory of a local copy of the' >&2
  echo '"aerospike-dev-notebooks.docker" repo before running this script.' >&2
  hints=$( find $HOME -type d -name notebooks 2>/dev/null | grep 'aerospike-dev-notebooks.docker/notebooks' )
  if [[ hints ]] ; then
    echo '' >&2
    echo 'Maybe try one of these:' >&2
    echo $hints >&2
  fi
  exit 1
fi

# Record md5sum so we can check whether we changed the file
old_sum=$( md5sum $OUTPUT_FILE 2>/dev/null)

{
  echo "${HEADER_TEXT}"
  echo ""

  echo ""
  view_url="${VIEWER_URL}"
  launch_url="${BINDER_URL}"
  echo "All Notebooks | [View All](${view_url}) | [Launch in Binder](${launch_url})"
  echo ":-------- | ---- | ------"
  nbs=$( get_notebooks . )
  print_notebook_rows "$nbs"

  view_url="${VIEWER_URL}/java"
  launch_url="${BINDER_URL}java"
  echo " | | | | "
  echo "**Java  Notebooks** | [View All](${view_url}) | [Launch in Binder](${launch_url})"
  echo " | | | | "
  nbs=$( get_notebooks ./java )
  print_notebook_rows "$nbs"

  view_url="${VIEWER_URL}/python"
  launch_url="${BINDER_URL}python"
  echo " | | | | "
  echo "**Python  Notebooks** | [View All](${view_url}) | [Launch in Binder](${launch_url})"
  echo " | | | | "
  nbs=$( get_notebooks ./python )
  print_notebook_rows "$nbs"

  echo ""
} > ${OUTPUT_FILE}

# Compute new md5sum and check whether it's different
new_sum=$( md5sum $OUTPUT_FILE )

if [[ "${old_sum}" == "${new_sum}" ]] ; then
  echo "${OUTPUT_FILE} did not change" >&2
else
  echo "${OUTPUT_FILE} changed" >&2
  git add ${OUTPUT_FILE}
fi
