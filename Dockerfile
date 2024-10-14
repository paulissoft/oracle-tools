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
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.json devbox.lock ./

RUN devbox run -- echo "Installed Packages."

# Only copy sources necessary for Maven builds
COPY pom.xml .
COPY conf ./conf
COPY db ./db
COPY apex ./apex

RUN sudo ln -s /app/conf /mnt/conf && sudo ln -s /app /mnt/oracle-tools

CMD ["/usr/bin/sh"]
