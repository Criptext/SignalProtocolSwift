//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "AxolotlInMemoryStore.h"
#import "AxolotlExceptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface AxolotlInMemoryStore ()

@property NSMutableDictionary<NSString *, NSMutableDictionary *> *sessionRecords;

// Signed PreKey Store

@property NSMutableDictionary *preKeyStore;
@property NSMutableDictionary *signedPreKeyStore;

@property NSMutableDictionary *trustedKeys;

@property ECKeyPair *_identityKeyPair;
@property int _localRegistrationId;

@end

@implementation AxolotlInMemoryStore


# pragma mark General

- (instancetype)init{
    self = [super init];
    
    if (self) {
        self._identityKeyPair     = [Curve25519 generateKeyPair];
        self._localRegistrationId = arc4random() % 16380;
        
        _preKeyStore = [NSMutableDictionary dictionary];
        _signedPreKeyStore = [NSMutableDictionary dictionary];
        _trustedKeys = [NSMutableDictionary dictionary];
        _sessionRecords = [NSMutableDictionary dictionary];
    }
    
    return self;
}

# pragma mark Signed PreKey Store

- (SignedPreKeyRecord *)loadSignedPrekey:(int)signedPreKeyId{
    if (![[self.signedPreKeyStore allKeys] containsObject:[NSNumber numberWithInt:signedPreKeyId]]) {
        @throw [NSException exceptionWithName:InvalidKeyIdException reason:@"No such signedprekeyrecord" userInfo:nil];
    }
    
    return [self.signedPreKeyStore objectForKey:[NSNumber numberWithInt:signedPreKeyId]];
}

- (nullable SignedPreKeyRecord *)loadSignedPrekeyOrNil:(int)signedPreKeyId
{
    if ([self containsSignedPreKey:signedPreKeyId]) {
        return [self loadSignedPrekey:signedPreKeyId];
    } else {
        return nil;
    }
}

- (NSArray<SignedPreKeyRecord *> *)loadSignedPreKeys
{
    NSMutableArray *results = [NSMutableArray array];
    
    for (SignedPreKeyRecord *signedPrekey in [self.signedPreKeyStore allValues]) {
        [results addObject:signedPrekey];
    }
    
    return results;
}

- (void)storeSignedPreKey:(int)signedPreKeyId signedPreKeyRecord:(SignedPreKeyRecord *)signedPreKeyRecord{
    [self.signedPreKeyStore setObject:signedPreKeyRecord forKey:[NSNumber numberWithInteger:signedPreKeyId]];
}

- (BOOL)containsSignedPreKey:(int)signedPreKeyId{
    if ([[self.signedPreKeyStore allKeys] containsObject:[NSNumber numberWithInteger:signedPreKeyId]]) {
        return TRUE;
    }
    
    return FALSE;
}

- (void)removeSignedPreKey:(int)signedPrekeyId{
    [self.signedPreKeyStore removeObjectForKey:[NSNumber numberWithInteger:signedPrekeyId]];
}

# pragma mark PreKey Store

- (PreKeyRecord *)loadPreKey:(int)preKeyId{
    if (![[self.preKeyStore allKeys] containsObject:[NSNumber numberWithInt:preKeyId]]) {
        @throw [NSException exceptionWithName:InvalidKeyIdException reason:@"No such signedprekeyrecord" userInfo:nil];
    }
    
    return [self.preKeyStore objectForKey:[NSNumber numberWithInt:preKeyId]];
}

- (NSArray *)loadPreKeys{
    NSMutableArray *results = [NSMutableArray array];
    
    for (PreKeyRecord *prekey in [self.preKeyStore allValues]) {
        [results addObject:prekey];
    }
    
    return results;
}

- (void)storePreKey:(int)preKeyId preKeyRecord:(PreKeyRecord *)record{
    [self.preKeyStore setObject:record forKey:[NSNumber numberWithInt:preKeyId]];
}

- (BOOL)containsPreKey:(int)preKeyId{
    if ([[self.preKeyStore allKeys] containsObject:[NSNumber numberWithInteger:preKeyId]]) {
        return TRUE;
    }
    
    return FALSE;
}

- (void)removePreKey:(int)preKeyId{
    [self.preKeyStore removeObjectForKey:[NSNumber numberWithInt:preKeyId]];
}

# pragma mark IdentityKeyStore

- (nullable ECKeyPair *)identityKeyPair
{
    return __identityKeyPair;
}

- (int)localRegistrationId{
    return __localRegistrationId;
}

- (BOOL)saveRemoteIdentity:(NSData *)identityKey recipientId:(NSString *)recipientId
{
    NSData *existingKey = [self.trustedKeys objectForKey:recipientId];

    if ([existingKey isEqualToData:existingKey]) {
        return NO;
    }

    [self.trustedKeys setObject:identityKey forKey:recipientId];
    return YES;
}

- (BOOL)isTrustedIdentityKey:(NSData *)identityKey
                 recipientId:(NSString *)recipientId
                   direction:(TSMessageDirection)direction
{

    NSData *data = [self.trustedKeys objectForKey:recipientId];
    if (!data) {
        // Trust on first use
        return YES;
    }

    switch (direction) {
        case TSMessageDirectionIncoming:
            return YES;
        case TSMessageDirectionOutgoing:
            // In a real implementation you may wish to ensure the use has been properly notified of any
            // recent identity change before sending outgoing messages.
            return [data isEqualToData:identityKey];
        case TSMessageDirectionUnknown:
            NSAssert(NO, @"unknown message direction");
            return NO;
    }
}

# pragma mark Session Store

-(SessionRecord*)loadSession:(NSString*)contactIdentifier deviceId:(int)deviceId{
    SessionRecord *sessionRecord = [[self deviceSessionRecordsForContactIdentifier:contactIdentifier] objectForKey:[NSNumber numberWithInteger:deviceId]];
    
    if (!sessionRecord) {
        sessionRecord = [SessionRecord new];
    }
    
    return sessionRecord;
}

- (NSArray*)subDevicesSessions:(NSString*)contactIdentifier{
    return [[self deviceSessionRecordsForContactIdentifier:contactIdentifier] allKeys];
}

- (NSMutableDictionary *)deviceSessionRecordsForContactIdentifier:(NSString *)contactIdentifier
{
    return [self.sessionRecords objectForKey:contactIdentifier];
}

- (void)storeSession:(NSString*)contactIdentifier deviceId:(int)deviceId session:(SessionRecord *)session{
    NSAssert(session, @"Session can't be nil");
    NSMutableDictionary *deviceSessions = self.sessionRecords[contactIdentifier];
    if (!deviceSessions) {
        deviceSessions = [NSMutableDictionary new];
    }
    deviceSessions[@(deviceId)] = session;

    self.sessionRecords[contactIdentifier] = deviceSessions;
}

- (BOOL)containsSession:(NSString*)contactIdentifier deviceId:(int)deviceId{
    
    if ([[self.sessionRecords objectForKey:contactIdentifier] objectForKey:[NSNumber numberWithInt:deviceId]]){
        return YES;
    }
    return NO;
}

- (void)deleteSessionForContact:(NSString *)contactIdentifier deviceId:(int)deviceId
{
    NSMutableDictionary<NSNumber *, SessionRecord *> *sessions =
        [self deviceSessionRecordsForContactIdentifier:contactIdentifier];
    [sessions removeObjectForKey:@(deviceId)];
}

- (void)deleteAllSessionsForContact:(NSString *)contactIdentifier
{
    [self.sessionRecords removeObjectForKey:contactIdentifier];
}

@end

NS_ASSUME_NONNULL_END
