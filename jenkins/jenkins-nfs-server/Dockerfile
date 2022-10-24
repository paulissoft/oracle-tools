ARG NFS_GRP=jenkins
ARG NFS_GID=1000
ARG NFS_USR=jenkins
ARG NFS_UID=1000

FROM erichough/nfs-server

ARG NFS_GRP
ARG NFS_GID
ARG NFS_USR
ARG NFS_UID

COPY exports.txt /etc/exports
COPY hosts.allow /etc/
COPY hosts.deny /etc/

RUN	addgroup --gid $NFS_GID $NFS_GRP && \
		adduser --no-create-home --disabled-password --gecos "" --uid $NFS_UID --ingroup $NFS_GRP $NFS_USR && \
		mkdir --parents /nfs/workspace /nfs/repository && \
		touch /nfs/workspace/workspace.txt /nfs/repository/repository.txt && \
		chown -R $NFS_USR:$NFS_GRP /nfs && \
		chown -R $NFS_USR:$NFS_GRP /var/lib/nfs
		
# The last line to solve:
# ---
# Error response from daemon: error while mounting volume '/var/lib/docker/volumes/ubuntu-1-volume/_data':
# failed to mount local volume: mount ::/var/lib/docker/volumes/ubuntu-1-volume/_data, data: addr=192.168.1.3,nfsvers=4,nolock,soft: connection refused
# ---



