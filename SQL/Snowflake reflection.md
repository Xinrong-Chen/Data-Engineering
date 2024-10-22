1. Snowflake uses micro-partitioning and data clustering to replace traditional indexes (like those in other relational databases such as MySQL or PostgreSQL).

2. Internal and external stages(eg. AWS S3, Azure Blob, or GCP) are used for faster data loading.

3. Share a view instead of the table for data security.

4. Materialized view:
   * Pre-computed data is physically stored ("cached") in the table, taking up storage.
   * Data is guaranteed to be up-to-date when queried, resulting in better query performance and data consistency.
Temporary and transient tables are used for intermediate results. They do not have a fail-safe period like permanent tables.

5. A temporary table exists only for the duration of the session.
6. A transient table persists until explicitly dropped and can be viewed by all users with granted privileges.
