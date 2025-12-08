@echo off
echo Deploying Firestore indexes and rules...

REM Deploy Firestore rules
firebase deploy --only firestore:rules

REM Deploy Firestore indexes
firebase deploy --only firestore:indexes

echo Deployment complete!
pause