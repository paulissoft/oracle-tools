ARG VERSION_DEVBOX=0.13.4

# ---
# Stage 1 (base): install devbox and its packages
# ---
FROM jetpackio/devbox:${VERSION_DEVBOX} as base

# Installing your devbox project
WORKDIR /app
USER root:root
RUN mkdir -p /app && chown ${DEVBOX_USER}:${DEVBOX_USER} /app
USER ${DEVBOX_USER}:${DEVBOX_USER}

# Copy the configuration files of the tooling
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.json devbox.lock ./

RUN devbox run -- echo "Installing packages"

# cleanup
RUN nix-store --gc

# ---
# Stage 2 (final): create a minimal image based on alpine (having /bin/sh)
# ---
FROM scratch

COPY --from=base / /

WORKDIR /app
USER ${DEVBOX_USER}:${DEVBOX_USER}

COPY . .

RUN ln -s /app/conf /mnt/conf && ln -s . /mnt/oracle-tools

ENTRYPOINT ["/bin/sh"]
