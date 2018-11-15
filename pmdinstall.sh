#!/bin/sh
#   -b binary distribution Name ie: "pmd-bin-6.9.0"
#   -e default download file Extension ie: ".zip"
#   -r PATH to a existing Repository, project root folder in git terms "git rev-parse --show-toplevel"
#   -u base download url ie: "https://github.com/pmd/pmd/releases/download/pmd_releases%2F6.9.0/"
#
#   ./pmdinstall -b "pmd-bin-6.9.0" -e ".zip" -u "https://github.com/pmd/pmd/releases/download/pmd_releases%2F6.9.0/"
#   ./pmdinstall -r "/Users/mike/Workspace/FluentPageObjects"
#

binName="pmd-bin-6.9.0"
dwnUrl="https://github.com/pmd/pmd/releases/download/pmd_releases%2F6.9.0/"
defDwnExt=".zip"
gitHooks=".git/hooks"
preCommitScript="pre-commit"
txRulesFile="TXCustomRules.xml"
pmdInstallHome=$(pwd)

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)                 machine=Linux;;
    Darwin*)                machine=Mac;;
    CYGWIN*|MINGW*|MSYS*)   machine=Windows;;
                       *)   machine="UNKNOWN:${unameOut}"
esac

while getopts b:e:r:u: option
do
    case "${option}"
        in
        b) binName=${OPTARG};;
        e) defDwnExt=${OPTARG};;
        r) repoPath=${OPTARG};;
        u) dwnUrl=${OPTARG};;        
    esac
done

if [ ! -f "$binName$defDwnExt" ];
then
    curl -OL "$dwnUrl$binName$defDwnExt"
    if [ $? -ne 0 ];
    then
        echo "ERROR: downloading $binName$defDwnExt from $dwnUrl"
        exit 1
    fi
fi

if [ -f "$binName$defDwnExt" ];
then
    unzip -o "$binName$defDwnExt"
    if [ $? -ne 0 ];
    then
        echo "ERROR: Unable to decompress Zip file $binName$defDwnExt"
        exit 1
    fi
fi

cd $binName/bin

pmd="pwd/run.sh pmd"

wd=$(pwd)

echo "************************************"

if [ $machine = "Windows" ];
then
    echo "WINDOWS ONLY: Notice pmd.bat Script should be used on windows environments"
fi    

echo "INFO: Updating PATH .bash_profile"
echo "export PATH=\"$PATH:$wd\"" >> ~/.bash_profile

if [ !$machine = "Windows" ];
then
    echo "alias pmd='$wd/run.sh pmd'" >> ~/.bash_profile
else
    echo "alias pmd='$wd/pmd.bat'" >> ~/.bash_profile
fi

cd $pmdInstallHome

echo "************************************"
echo "INFO: Attempting to reload environment"

$(source ~/.bash_profile);
$(. ~/.bash_profile);

echo "************************************"
echo "INFO: PMD Installation completed"
echo "************************************"

if [ ! -z $repoPath ];
then
    echo "INFO: Checking GIT repo at $repoPath "
    if [ -d "$repoPath/$gitHooks" ];
    then
        echo "INFO: $repoPath Directory looks Valid GIT repository"
        echo "INFO: Attempt to Enable pre-commit hook in $repoPath repository"
      
        if [ -f $preCommitScript ];
        then
            
            cp "$preCommitScript" "$repoPath/$gitHooks"
             
            if [ $? -ne 0 ];
            then
                echo "ERROR: failed to copy $preCommitScript script to "$repoPath/$gitHooks" folder"
                exit 1
            else
                if [ -f "$repoPath/$gitHooks/$preCommitScript" ];
                then
                    echo "INFO: $preCommitScript script succesfully copied to "$repoPath/$gitHooks" folder"
                    echo "INFO: Attemp to grant execution privileges to $repoPath/$gitHooks/$preCommitScript"

                    chmod a+x "$repoPath/$gitHooks/$preCommitScript"

                    if [ -x "$repoPath/$gitHooks/$preCommitScript" ];
                    then
                        echo "INFO: $preCommitScript script granted Execution Privileges"
                    else
                        echo "WARNING: $preCommitScript script was no set as Executable you'll need to grant privileges manually"
                    fi
                fi
            fi
        else
            echo "ERROR: $preCommitScript script not found in current directory"
            echo "ERROR: you'll need to add it manually"
            exit 1
        fi

        if [ -f $txRulesFile ];
        then  
            echo "INFO: Found Rules File attept to Copy to Hooks Directory."
            
            cp "$txRulesFile" "$repoPath/$gitHooks"

            if [ $? -ne 0 ];
            then
                echo "ERROR: Failed to copy Rules file: $txRulesFile to destination: $repoPath/$gitHooks"
            fi
        fi    

    else
        echo "ERROR: $repoPath Directory does not look like a valid GIT repository"
        echo "ERROR: you'll need to add $preCommitScript script manually"
        exit 1
    fi
    echo "INFO: pre-commit hook configuration completed SUCCESSFULLY"
fi
