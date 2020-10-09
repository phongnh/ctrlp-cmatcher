#!/usr/bin/env sh

chkPython3()
{
    cmd=$1
    ret=$($cmd -V 2>&1)
    case "$ret" in
    "Python 3."*)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

findPython3()
{
    cmd_list="python3.8 python3.7 python3.6 python3 python"
    for cmd in $cmd_list; do
        if chkPython3 $cmd; then
            found_python=$cmd
            break
        fi
    done

    if [ "$found_python" = "" ]; then
        echo "cannot find python3 automatically" >&2
        exit 1
    fi

    echo $found_python
}

python=$(findPython3)
echo "find python3 -> $python"

cd autoload
rm -rf build
$python setup.py build && cp -v build/lib*/fuzzycomt*.so fuzzycomt.so
