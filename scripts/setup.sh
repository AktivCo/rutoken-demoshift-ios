SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
python3 ${SCRIPT_DIR}/download_deps.py -p ios
mkdir ${SCRIPT_DIR}/../Frameworks
find ${SCRIPT_DIR}/../external -type d -name "*.xcframework" | xargs -I {} cp -R {} ${SCRIPT_DIR}/../Frameworks/
