# Flyway migration container
FROM flyway/flyway:10-alpine

# Copy migration scripts
COPY migrations /flyway/sql

# Copy configuration
COPY flyway.conf /flyway/conf/flyway.conf

# Set entrypoint to run migrations
ENTRYPOINT ["flyway"]
CMD ["migrate"]
