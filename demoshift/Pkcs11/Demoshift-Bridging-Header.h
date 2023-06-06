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
#include <openssl/cms.h>
#include <openssl/err.h>

#include <rtengine/engine.h>

STACK_OF(X509)* exposed_sk_X509_new_null(void);

int exposed_sk_X509_push(STACK_OF(X509)* certStack, X509* cert);

void exposed_sk_X509_pop_free(STACK_OF(X509)* certStack);

#endif /* Demoshift_Bridging_Header_h */
