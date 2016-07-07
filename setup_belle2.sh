# add tools directory to path
export BELLE2_TOOLS=`python -c 'from __future__ import print_function; import os,sys;print(os.path.realpath(sys.argv[1]))' $(dirname ${BASH_SOURCE:-$0})`
if [ -n "${PATH}" ]; then
  export PATH=${BELLE2_TOOLS}:${PATH}
else
  export PATH=${BELLE2_TOOLS}
fi
if [ -n "${PYTHONPATH}" ]; then
  export PYTHONPATH=${BELLE2_TOOLS}:${PYTHONPATH}
else
  export PYTHONPATH=${BELLE2_TOOLS}
fi

# set top directory of Belle II software installation
if [ -z "${VO_BELLE2_SW_DIR}" ]; then
  export VO_BELLE2_SW_DIR=`python -c 'from __future__ import print_function; import os,sys;print(os.path.realpath(sys.argv[1]))' ${BELLE2_TOOLS}/..`
fi

# set top directory of external software
if [ -z "${BELLE2_EXTERNALS_TOPDIR}" ]; then
  export BELLE2_EXTERNALS_TOPDIR=${VO_BELLE2_SW_DIR}/externals
fi

# set architecture, default option and sub directory name
export BELLE2_ARCH=`uname -s`_`uname -m`
export BELLE2_OPTION=opt
export BELLE2_SUBDIR=${BELLE2_ARCH}/${BELLE2_OPTION}
export BELLE2_EXTERNALS_OPTION=opt
export BELLE2_EXTERNALS_SUBDIR=${BELLE2_ARCH}/${BELLE2_EXTERNALS_OPTION}

# set user name
if [ -z "${BELLE2_USER}" ]; then
  export BELLE2_USER=${USER}
  if [ -z "${BELLE2_USER}" ]; then
    export BELLE2_USER=`id -nu` 
  fi
fi

# set location of Belle II code repositories
if [ -z "${BELLE2_GIT_SERVER}" ]; then
  if [ "${BELLE2_GIT_ACCESS}" = "ssh" -o "${BELLE2_GIT_ACCESS}" != "http" -a -f ${HOME}/.ssh/id_rsa.pub ]; then
    export BELLE2_GIT_SERVER=ssh://git@stash.desy.de:7999
  else
    export BELLE2_GIT_SERVER=https://${BELLE2_USER}@stash.desy.de/scm
  fi
fi
if [ -z "${BELLE2_SOFTWARE_REPOSITORY}" ]; then
  export BELLE2_SOFTWARE_REPOSITORY=${BELLE2_GIT_SERVER}/b2/software.git
fi
if [ -z "${BELLE2_EXTERNALS_REPOSITORY}" ]; then
  export BELLE2_EXTERNALS_REPOSITORY=${BELLE2_GIT_SERVER}/b2/externals.git
fi
if [ -z "${BELLE2_ANALYSES_PROJECT}" ]; then
  export BELLE2_ANALYSES_PROJECT=b2a
fi
if [ -z "${BELLE2_DOWNLOAD}" ]; then
  export BELLE2_DOWNLOAD="--no-check-certificate --user=belle2 --password=Aith4tee https://b2-master.belle2.org/download"
fi

# list of packages that are excluded by default
if [ -z "${BELLE2_EXCLUDE_PACKAGES}" ]; then
  export BELLE2_EXCLUDE_PACKAGES="daq eutel topcaf testbeam"
fi

# define function for release setup
function setuprel
{
  eval "`${BELLE2_TOOLS}/setuprel.py $* || echo 'return 1'`"
}

# define function for analysis setup
function setupana
{
  eval "`${BELLE2_TOOLS}/setupana.py $* || echo 'return 1'`"
}

# define function for option selection
function setoption
{
  eval "`${BELLE2_TOOLS}/setoption.py $* || echo 'return 1'`"
}

# define function for externals option selection
function setextoption
{
  eval "`${BELLE2_TOOLS}/setextoption.py $* || echo 'return 1'`"
}
# inform user about successful setup
echo "Belle II software tools set up at: ${BELLE2_TOOLS}"

# check python version
if ! python -c 'import sys; assert(sys.hexversion>0x02070600)' 2> /dev/null; then
  echo "Warning: Your Python version is too old, basf2 will not work properly." 
fi

# check for a newer version
if [ -z "${BELLE2_NO_TOOLS_CHECK}" ]; then
  pushd ${BELLE2_TOOLS} > /dev/null
  git fetch --dry-run &> /dev/null
  if [ $? != 0 ]; then
    echo
    echo "Warning: Could not access remote git repository in non-interactive mode."
    echo "-------> Please make sure you can successfully run the following command"
    echo "         WITHOUT interactive input:"
    echo
    echo "           git fetch --dry-run"
    echo
  else
    tmp=`mktemp /tmp/belle2_tmp.XXXX`
    git fetch --dry-run 2>&1 | grep -v X11 > $tmp
    FETCH_CHECK=`cat $tmp | wc -l`
    rm -f $tmp
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    if [ ${FETCH_CHECK} != 0 -o ${LOCAL} != ${REMOTE} ]; then
      echo
      echo "WARNING: The version of the tools you are using is outdated."
      echo "-------> Please update the tools with"
      echo
      echo "           git pull --rebase"
      echo
      echo "         and source the new setup_belle2 script."
      echo
    fi
  fi
  popd  > /dev/null
fi
