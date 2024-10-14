ARG VERSION_DEVBOX=0.13.4
ARG VERSION_ALPINE=3.20.3

ARG UID=1000
ARG GID=1000

# ---
# Stage 1 (base): install devbox and its packages
# ---
FROM jetpackio/devbox:${VERSION_DEVBOX} as base

# Installing your devbox project
WORKDIR /mnt/conf
WORKDIR /mnt/oracle-tools
WORKDIR /app/conf

WORKDIR /app
USER root:root
RUN ln -s /app/conf /mnt/conf && \
		ln -s /app /mnt/oracle-tools && \
		chown ${DEVBOX_USER}:${DEVBOX_USER} /app
USER ${DEVBOX_USER}:${DEVBOX_USER}
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.json devbox.lock ./

RUN devbox run -- echo "Installed Packages."

# Copy all the run time dependencies of python into /tmp/nix-store-closure.
RUN packages=$(devbox list -q | cut -d '#' -f 2 | sed 's/maven/mvn/') && \
		echo "packages: ${packages}" && \
		installed_packages=$(echo ${packages} | xargs devbox run -- type 2>/dev/null | awk '{print $3}') && \
		echo "installed_packages: ${installed_packages}" && \
		deps=$(nix-store -qR ${installed_packages}) && \
		echo "Output references (Runtime dependencies): $deps" && \
		mkdir /tmp/nix-store-closure && \
		cp -R $deps /tmp/nix-store-closure

# ---
# Stage 2 (final): create a minimal image based on alpine (having /bin/sh)
# ---
ARG VERSION_ALPINE
FROM alpine:${VERSION_ALPINE} as final

# re-import these arguments
ARG UID
ARG GID

ENV DEVBOX_USER=devbox
RUN addgroup --system ${DEVBOX_USER} --gid ${GID} && \
    adduser --uid ${UID} --system --ingroup ${DEVBOX_USER} ${DEVBOX_USER}

USER ${DEVBOX_USER}:${DEVBOX_USER}

WORKDIR /app

# Copy the runtime dependencies into /nix/store
# Note we don't actually have nix installed on this container. But that's fine,
# we don't need it, the built code only relies on the given files existing, not
# Nix.
COPY --from=base --chown=${DEVBOX_USER}:${DEVBOX_USER} /tmp/nix-store-closure /nix/store
COPY --from=base --chown=${DEVBOX_USER}:${DEVBOX_USER} /app/.devbox/nix/profile/default/bin /app/.devbox/nix/profile/default/bin
COPY --from=base /mnt /mnt

ENV PATH=/app/.devbox/nix/profile/default/bin:${PATH}

# Only copy sources necessary for Maven builds
COPY pom.xml .
COPY conf ./conf
COPY db ./db
COPY apex ./apex

CMD ["/bin/sh"]
