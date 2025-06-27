# Firestore Security Rules Documentation

## Overview

This document outlines the comprehensive security rules implemented for the My Tool Shed Firestore database. The rules are designed to protect user data while enabling the community tool-sharing functionality.

## Security Principles

### 1. **Authentication Required**
- All operations require user authentication
- No anonymous access to any data
- User identity is verified through Firebase Auth

### 2. **Data Ownership**
- Users can only access and modify their own data
- Tool owners have full control over their tools
- Community features respect ownership boundaries

### 3. **Data Validation**
- All incoming data is validated for structure and content
- Required fields are enforced
- Data types are verified
- Rating values are constrained to valid ranges

### 4. **Principle of Least Privilege**
- Users only have access to data they need
- Read access is granted where appropriate for community features
- Write access is strictly controlled

## Database Structure

### Collections

1. **`users/{userId}`** - User profiles
   - Subcollection: `tools/{toolId}` - User's personal tools
     - Subcollection: `borrowHistory/{historyId}` - Tool borrowing history

2. **`tools/{toolId}`** - Community-available tools

3. **`community_members/{memberId}`** - Community member profiles

4. **`tool_ratings/{ratingId}`** - Tool ratings and reviews

5. **`borrow_requests/{requestId}`** - Tool borrowing requests (future feature)

6. **`notifications/{notificationId}`** - User notifications (future feature)

## Security Rules Breakdown

### Helper Functions

```javascript
// Authentication check
function isAuthenticated() {
  return request.auth != null;
}

// Ownership verification
function isOwner(data) {
  return isAuthenticated() && request.auth.uid == data.ownerId;
}

// Document ownership check
function isDocumentOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}

// Tool borrowing permission
function canBorrowTool(toolData) {
  return isAuthenticated() && 
         toolData.isAvailableForCommunity == true &&
         (toolData.allowedBorrowers.hasAny([request.auth.uid]) || 
          toolData.allowedBorrowers.size() == 0);
}
```

### Data Validation Functions

```javascript
// Tool data validation
function isValidToolData(data) {
  return data.keys().hasAll(['name', 'ownerId', 'ownerName']) &&
         data.name is string &&
         data.name.size() > 0 &&
         data.ownerId is string &&
         data.ownerId.size() > 0 &&
         data.ownerName is string &&
         data.ownerName.size() > 0;
}

// Community member validation
function isValidCommunityMemberData(data) {
  return data.keys().hasAll(['name']) &&
         data.name is string &&
         data.name.size() > 0;
}

// Tool rating validation
function isValidToolRatingData(data) {
  return data.keys().hasAll(['toolId', 'raterId', 'raterName', 'borrowerId', 'borrowerName', 'rating']) &&
         data.toolId is string &&
         data.raterId is string &&
         data.raterName is string &&
         data.borrowerId is string &&
         data.borrowerName is string &&
         data.rating is number &&
         data.rating >= 0.0 &&
         data.rating <= 5.0;
}
```

## Collection-Specific Rules

### User Profiles (`users/{userId}`)

**Read Access**: All authenticated users can read user profiles for community features
**Write Access**: Users can only modify their own profile
**Validation**: Requires valid community member data structure

### User Tools (`users/{userId}/tools/{toolId}`)

**Read Access**: Users can only read their own tools
**Write Access**: Users can only create/update/delete their own tools
**Validation**: Requires valid tool data with proper ownership

### Borrow History (`users/{userId}/tools/{toolId}/borrowHistory/{historyId}`)

**Access**: Users can only access borrow history for their own tools
**Validation**: Requires borrower information and date fields

### Community Tools (`tools/{toolId}`)

**Read Access**: All authenticated users can read community-available tools
**Write Access**: Only tool owners can create/update/delete community tools
**Validation**: Tools must be marked as available for community

### Community Members (`community_members/{memberId}`)

**Read Access**: All authenticated users can read community member profiles
**Write Access**: Users can only modify their own community member profile
**Validation**: Requires valid community member data structure

### Tool Ratings (`tool_ratings/{ratingId}`)

**Read Access**: All authenticated users can read tool ratings
**Write Access**: Users can only create/update/delete their own ratings
**Validation**: Requires valid rating data with proper constraints (0-5 stars)

## Security Features

### 1. **Data Integrity**
- All required fields are enforced
- Data types are validated
- Rating values are constrained to valid ranges
- Timestamps are required for temporal data

### 2. **Access Control**
- User-specific data is protected
- Community features maintain privacy boundaries
- Tool ownership is strictly enforced

### 3. **Community Safety**
- Users can only rate tools they've borrowed
- Trust relationships are respected
- Borrowing permissions are enforced

### 4. **Future-Proofing**
- Rules include placeholders for future features (borrow requests, notifications)
- Extensible structure for new collections
- Consistent security patterns

## Testing Security Rules

### Local Testing
```bash
# Test rules locally
firebase emulators:start --only firestore

# Test specific rules
firebase firestore:rules:test
```

### Production Deployment
```bash
# Deploy rules to production
firebase deploy --only firestore:rules
```

## Security Best Practices

### 1. **Regular Audits**
- Review security rules quarterly
- Test with different user scenarios
- Monitor for unusual access patterns

### 2. **Data Minimization**
- Only collect necessary user data
- Implement data retention policies
- Provide data deletion capabilities

### 3. **Monitoring**
- Set up Firebase Security Rules monitoring
- Log security rule violations
- Monitor for suspicious activity

### 4. **User Privacy**
- Respect user privacy preferences
- Implement proper data anonymization
- Follow GDPR/CCPA compliance

## Common Security Scenarios

### Scenario 1: User Creates a Tool
- ✅ User authenticated
- ✅ Tool has valid data structure
- ✅ User is the owner
- ✅ Tool created in user's collection

### Scenario 2: User Shares Tool with Community
- ✅ User authenticated
- ✅ User owns the tool
- ✅ Tool marked as community-available
- ✅ Tool copied to community collection

### Scenario 3: User Rates a Tool
- ✅ User authenticated
- ✅ User is the rater
- ✅ Rating data is valid
- ✅ Rating within 0-5 range

### Scenario 4: User Borrows a Tool
- ✅ User authenticated
- ✅ Tool is available for community
- ✅ User is in allowed borrowers list (or list is empty)
- ✅ Borrow history created

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Check user authentication
   - Verify data ownership
   - Ensure required fields are present

2. **Data Validation Errors**
   - Check data structure
   - Verify field types
   - Ensure required fields are not empty

3. **Community Access Issues**
   - Verify tool is marked as community-available
   - Check borrowing permissions
   - Ensure user is in allowed borrowers list

### Debugging Tips

1. **Enable Security Rules Logging**
   ```javascript
   // In Firebase Console
   // Go to Firestore > Rules > Monitor
   ```

2. **Test Rules Locally**
   ```bash
   firebase emulators:start --only firestore
   ```

3. **Use Firebase Console**
   - Test queries in Firestore console
   - Check rule evaluation results
   - Monitor real-time usage

## Compliance and Legal

### GDPR Compliance
- Users can request data deletion
- Data is properly anonymized
- User consent is respected

### CCPA Compliance
- Users can opt out of data sharing
- Data access is transparent
- User rights are protected

## Conclusion

These security rules provide a robust foundation for protecting user data while enabling the community tool-sharing functionality. Regular reviews and updates ensure continued security as the application evolves.

For questions or concerns about security, please contact the development team. 