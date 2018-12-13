#!/bin/bash

mkdir -p singlem-x86_64.AppImage/singlem.AppDir
cd singlem-x86_64.AppImage/
wget -q https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

cd singlem.AppDir
HERE=$(dirname $(readlink -f "${0}"))

bash ../Miniconda3-latest-Linux-x86_64.sh -b -p ./conda
rm ../Miniconda3-latest-Linux-x86_64.sh
PATH="${HERE}"/conda/bin:$PATH

conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda create -n singlem python=2.7.15 numpy=1.15.2 diamond=0.9.22 hmmer=3.2.1 \
  krona=2.7 orfm=0.7.1 pplacer=1.1.alpha19 -y
source activate singlem
mkdir bin
wget https://github.com/ctSkennerton/fxtract/releases/download/2.3/fxtract2.3-Linux-64bit-static \
  -O bin/fxtract
chmod +x bin/fxtract
PATH=$PATH:$PWD/bin
pip install singlem
source deactivate

cd ..

cat > ./AppRun <<EOF
#!/bin/bash
HERE=$(dirname $(readlink -f "${0}"))
export PATH="${HERE}"/miniconda3/bin:$PATH
source activate singlem
singlem $@
EOF

chmod a+x ./AppRun

wget -O terminal_icon.png https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Terminalicon2.png/256px-Terminalicon2.png

cat > ./singlem.desktop <<EOF
[Desktop Entry]
Name=singlem
Exec=singlem
Icon=terminal_icon
Type=Application
StartupNotify=true
EOF

# mPies (metaProteomics in environmental sciences) creates annotated databases for metaproteomics analysis.
# Copyright 2018 Johannes Werner (Leibniz-Institute for Baltic Sea Research)
# Copyright 2018 Augustin Geron (University of Stirling)
# Copyright 2018 Sabine Matallana Surget (University of Stirling)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
