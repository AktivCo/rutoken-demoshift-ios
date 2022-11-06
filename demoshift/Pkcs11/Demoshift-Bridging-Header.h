//
//  Demoshift-Bridging-Header.h
//  demoshift
//
//  Created by Андрей Трифонов on 22.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

#ifndef Demoshift_Bridging_Header_h
#define Demoshift_Bridging_Header_h

#include <rtpkcs11ecp/rtpkcs11.h>
#include <rtpkcs11ecp/cryptoki.h>

#include <RtPcsc/rtnfc.h>
#include <RtPcsc/rtVcrPairing.h>
#include <RtPcsc/winscard.h>

#include <openssl/configuration.h>
#undef OPENSSL_NO_DEPRECATED
#define OPENSSL_SUPPRESS_DEPRECATED

#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/cms.h>
#include <openssl/bio.h>

#include <rtengine/engine.h>

STACK_OF(X509)* exposed_sk_X509_new_null(void);

void exposed_sk_X509_free(STACK_OF(X509)* certStack);

int exposed_sk_X509_push(STACK_OF(X509)* certStack, X509* cert);

const EVP_CIPHER* exposed_EVP_get_cipherbynid(int nid);

CMS_ContentInfo* exposed_PEM_read_bio_CMS(BIO* bio, CMS_ContentInfo** type, pem_password_cb* cb, void* u);

long exposed_BIO_get_mem_data(BIO *b, char **pp);

#endif /* Demoshift_Bridging_Header_h */
