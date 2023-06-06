//
//  Demoshift-Bridging.m
//  demoshift
//
//  Created by Vova Badyaev on 06.11.2022.
//  Copyright © 2022 Aktiv Co. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "Demoshift-Bridging-Header.h"


// The Swift compiler has limitations on using complex C macros,
// so some interfaces are unavailable and we need implement them by ourselves

STACK_OF(X509)* exposed_sk_X509_new_null(void) {
    return sk_X509_new_null();
}

int exposed_sk_X509_push(STACK_OF(X509)* certStack, X509* cert) {
    return sk_X509_push(certStack, cert);
}

void exposed_sk_X509_pop_free(STACK_OF(X509)* certStack) {
    sk_X509_pop_free(certStack, X509_free);
}
