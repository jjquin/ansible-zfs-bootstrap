# ansible-zfs-bootstrap
Reproducible Install of multiple linux distributions on ZFS root.

./bootstrap.sh will 
1. install git
2. setup the hostname and distro_id variables
3. clone the git repo.

if it fails or you wish to do it manually do the following:
1. install git with the distro package manager
2. run: echo "TARGET_HOST=your hostname" > /tmp/host.conf
3. run: echo "DISTRO_ID=$your distro id." >> /tmp/host.conf
4. cd to ~/ and run: git clone https://github.com/jjquin/ansible-zfs-bootstrap.git
