# migrate-to-new-render-backend

Migrated the "mixtape-backend" service from the old Render workspace/account to a new dedicated Render account to bypass free tier resource hour limits. This includes updating URL mappings inside the Flutter codebase, Web App manifests, and Trusted Web Activity (TWA) configs, as well as fixing a Firestore crash when inserting null/undefined song images and implementing cache TTL updates.
