//
//  Demoshift-Bridging.m
//  demoshift
//
//  Created by Vova Badyaev on 06.11.2022.
//  Copyright © 2022 Aktiv Co. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "Demoshift-Bridging-Header.h"


STACK_OF(X509)* exposed_sk_X509_new_null() {
    return sk_X509_new_null();
}

int exposed_sk_X509_push(STACK_OF(X509)* certStack, X509* cert) {
    return sk_X509_push(certStack, cert);
}

const EVP_CIPHER* exposed_EVP_get_cipherbynid(int nid) {
    return EVP_get_cipherbynid(nid);
}

void exposed_sk_X509_free(STACK_OF(X509)* certStack) {
    sk_X509_free(certStack);
}

CMS_ContentInfo* exposed_PEM_read_bio_CMS(BIO* bio, CMS_ContentInfo** type, pem_password_cb* cb, void* u) {
    return PEM_read_bio_CMS(bio, type, cb, u);
}

long exposed_BIO_get_mem_data(BIO *b, char **pp) {
    return BIO_get_mem_data(b, pp);
}
