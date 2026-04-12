# Bugfix Requirements Document

## Introduction

The NotificationsService's token removal method (used during logout) currently lacks retry logic. When token removal fails due to network issues or Firebase errors, the token remains registered in Firebase Cloud Messaging, causing users to continue receiving push notifications after they have logged out. This creates a poor user experience and potential privacy concern.

This bugfix adds retry logic with exponential backoff to ensure reliable token cleanup during logout while maintaining a non-blocking logout flow.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN token removal fails due to network connectivity issues THEN the system logs the error but does not retry, leaving the token registered

1.2 WHEN token removal fails due to Firebase service errors (e.g., timeout, rate limit) THEN the system catches the exception and continues without retry

1.3 WHEN token removal fails on first attempt THEN the user may continue receiving notifications after logout

### Expected Behavior (Correct)

2.1 WHEN token removal fails due to transient network issues THEN the system SHALL retry up to 3 times with exponential backoff (1s, 2s, 4s)

2.2 WHEN token removal fails due to Firebase service errors THEN the system SHALL retry with exponential backoff before giving up

2.3 WHEN token removal fails after maximum retry attempts THEN the system SHALL log the permanent failure gracefully and continue the logout flow without blocking the user

2.4 WHEN token removal succeeds on any retry attempt THEN the system SHALL log success and stop retrying

### Unchanged Behavior (Regression Prevention)

3.1 WHEN token removal succeeds on first attempt THEN the system SHALL CONTINUE TO complete immediately without unnecessary retries

3.2 WHEN user is not logged in THEN the system SHALL CONTINUE TO skip token removal as it does currently

3.3 WHEN logout flow is triggered THEN the system SHALL CONTINUE TO complete the logout regardless of token removal success or failure (non-blocking behavior)

3.4 WHEN token is successfully retrieved THEN the system SHALL CONTINUE TO call the removeFcmToken Cloud Function with correct parameters
