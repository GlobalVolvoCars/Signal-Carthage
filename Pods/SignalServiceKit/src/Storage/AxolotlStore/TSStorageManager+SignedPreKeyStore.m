//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSStorageManager+IdentityKeyStore.h"
#import "TSStorageManager+PreKeyStore.h"
#import "TSStorageManager+SignedPreKeyStore.h"
#import "TSStorageManager+keyFromIntLong.h"

#import <25519/Ed25519.h>
#import <AxolotlKit/AxolotlExceptions.h>
#import <AxolotlKit/NSData+keyVersionByte.h>

@implementation TSStorageManager (SignedPreKeyStore)

- (SignedPreKeyRecord *)generateRandomSignedRecord {
    ECKeyPair *keyPair = [Curve25519 generateKeyPair];

    // Signed prekey ids must be > 0.
    int preKeyId = 1 + arc4random_uniform(INT32_MAX - 1);
    return [[SignedPreKeyRecord alloc]
         initWithId:preKeyId
            keyPair:keyPair
          signature:[Ed25519 sign:keyPair.publicKey.prependKeyType withKeyPair:[self identityKeyPair]]
        generatedAt:[NSDate date]];
}

- (SignedPreKeyRecord *)loadSignedPrekey:(int)signedPreKeyId {
    SignedPreKeyRecord *preKeyRecord = [self signedPreKeyRecordForKey:[self keyFromInt:signedPreKeyId]
                                                         inCollection:TSStorageManagerSignedPreKeyStoreCollection];

    if (!preKeyRecord) {
        @throw
            [NSException exceptionWithName:InvalidKeyIdException reason:@"No key found matching key id" userInfo:@{}];
    } else {
        return preKeyRecord;
    }
}

- (NSArray *)loadSignedPreKeys {
    NSMutableArray *signedPreKeyRecords = [NSMutableArray array];

    YapDatabaseConnection *conn = [self newDatabaseConnection];

    [conn readWithBlock:^(YapDatabaseReadTransaction *transaction) {
      [transaction enumerateRowsInCollection:TSStorageManagerSignedPreKeyStoreCollection
                                  usingBlock:^(NSString *key, id object, id metadata, BOOL *stop) {
                                    [signedPreKeyRecords addObject:object];
                                  }];
    }];

    return signedPreKeyRecords;
}

- (void)storeSignedPreKey:(int)signedPreKeyId signedPreKeyRecord:(SignedPreKeyRecord *)signedPreKeyRecord {
    [self setObject:signedPreKeyRecord
              forKey:[self keyFromInt:signedPreKeyId]
        inCollection:TSStorageManagerSignedPreKeyStoreCollection];
}

- (BOOL)containsSignedPreKey:(int)signedPreKeyId {
    PreKeyRecord *preKeyRecord = [self signedPreKeyRecordForKey:[self keyFromInt:signedPreKeyId]
                                                   inCollection:TSStorageManagerSignedPreKeyStoreCollection];
    return (preKeyRecord != nil);
}

- (void)removeSignedPreKey:(int)signedPrekeyId {
    [self removeObjectForKey:[self keyFromInt:signedPrekeyId] inCollection:TSStorageManagerSignedPreKeyStoreCollection];
}

@end
