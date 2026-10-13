%%%
title = "Explicit RDAP Redirects"
abbrev = "Explicit RDAP Redirects"
ipr = "trust200902"
area = "Internet"
workgroup = "Registration Protocols Extensions (regext)"
consensus = true

[seriesInfo]
name = "Internet-Draft"
value = "draft-ietf-regext-rdap-referrals-05"
stream = "IETF"
status = "standard"

[[author]]
fullname="Gavin Brown"
organization = "ICANN"
  [author.address]
  email = "gavin.brown@fastmail.uk"
  uri = "https://icann.org"
  [author.address.postal]
  street = "12025 Waterfront Drive, Suite 300"
  city = "Los Angeles"
  region = "CA"
  code = "90292"
  country = "US"

[[author]]
fullname="Andy Newton"
organization = "ICANN"
  [author.address]
  email = "andy@hxr.us"
  uri = "https://icann.org"
  [author.address.postal]
  street = "12025 Waterfront Drive, Suite 300"
  city = "Los Angeles"
  region = "CA"
  code = "90292"
  country = "US"
%%%

.# Abstract

This document describes an RDAP extension that allows RDAP clients to request to
be redirected to a related RDAP record for a resource, and an RDAP extension that
gives RDAP clients the ability to request no redirection in other scenarios.
This document also defines new link relations that can be used in redirect requests
that can be used in query bootstrapping and navigating hierarchies, such as the hierarchies
described in RFC 9910.

{mainmatter}

# Introduction {#introduction}

Many Registration Data Access Protocol (RDAP, described in [@!RFC7480],
[@!RFC7481], [@!RFC9082], [@!RFC9083] and others) resources contain links to
related RDAP resources.

For example, in the domain space, an RDAP record for a domain name received from
the registry operator may include a link for the RDAP record for the same
object provided by the sponsoring registrar (for example, see
[@gtld-rdap-profile], in which links to registrar RDAP URLs are provided by using a link object with
the `related` relation), while in the IP address space, an RDAP record for an
address allocation may include links to enclosing or sibling prefixes.

In both cases, RDAP service users are often equally if not more interested in
these related RDAP resources than the resource provided by the TLD registry or
RIR. However, to obtain the URL(s) of the related resource(s), the client must request the full
RDAP record (which the server must then produce and deliver) in order to extract the
relevant URL from the "`links`" property of the object.

As deployed today, RDAP also has contrasting use cases for finding the registrations of IP resources.
As defined by [@!RFC9082], an RDAP server returns the most specific network registration containing
the information sought by the client. In practice, that information does not always sit on the server
found through the processes defined in [@!RFC9224], and the client is given a redirect from the [@!RFC9224] origin
server to a target server with the information. This practice is an optimization intended to satisfy the most
common use case for this type of query. However, there are use cases for which the client specifically seeks
the information on the [@!RFC9224] origin server and may wish to explicitly handled the referral to the more
specific target server.

This document describes extensions to RDAP that allow clients to signal preferences regarding
redirects issued by RDAP servers.

# redirects0 RDAP Extension

## RDAP Redirect Request

To request a redirect to a related resource, the client sends an HTTP `GET`
request with a URL of the form:

```
<base URL>redirects0_ref/<relation>/<lookup path>
```

The client replaces `<base URL>` with the applicable base URL (which, as per
[@RFC9224], has a trailing `/` character), `<relation>` with the desired
relationship type, and `<lookup path>` with the lookup path of the object being
sought (which, as per [@RFC9082], does not have a leading `/` character).

For example, the URL of a redirect query for the domain `example.com`, where the
base URL for the "`com`" TLD is `https://rdap.example.com/rdap/`, would be:

```
https://rdap.example.com/rdap/redirects0_ref/related/domain/example.com
```

The redirect query for the parent network of `192.0.2.42` with the base URL of
`https://rdap.example.net/` would be:

```
https://rdap.example.net/redirects0_ref/rdap-up/ip/192.0.2.42
```

As another example, the following URL would redirect the client to the appopriate
Geolocation Feed ([@RFC8805]) resource for `192.0.2.42`, using the `geofeed`
resource specified in [@RFC9877]:

```
https://rir-rdap.example.com/rdap/redirects0_ref/geofeed/ip/192.0.2.42
```

Lookup paths for domain names, IP networks, autonomous system numbers,
nameservers, and entities are described in [@!RFC9082]. Lookups defined by RDAP
extensions may also use this extension.

Redirect requests for searches, where more than one object is returned, and help
queries, as described by [@!RFC9083], are not supported. Servers MUST return an
HTTP 400 for these requests, and SHOULD return an RDAP error body containing a
notice with the type value of "redirect not available":

```
Client Request:

GET /redirects0_ref/related/help HTTP/1.1
Accept: application/rdap+json

Server Response:

HTTP/1.1 400 Bad Request
Content-Type: application/rdap+json

{
  "errorCode": 400,
  "type": "redirect not available",
  "title": "Redirect request for /help is not supported",
  "description": [
    "Only object lookups can be used with the redirects0_ref extension."
  ]
}
```

## RDAP Redirect Response

If the object specified in the request exists, a single appropriate link exists,
and the client is authorised to perform the request, the server response
**MUST**:

1. have an HTTP status code of 301 (Moved Permanently), 302 (Found), 303 (See
   Other), 307 (Temporary Redirect) or 308 (Permanent Redirect, see Section
   15.4.9 of [@!RFC9110]); and

2. include an HTTP `Location` header field, whose value contains the URL of the
   linked resource.

If the server cannot find an appropriate link, the response **MUST** have an
HTTP status of 404.

If an RDAP server holds in its datastore more than one relationship type for
an object, a scenario that is possible but not common, only one of the URLs, as
determined by server policy, can be returned.

The following examples use the HTTP/1.1 message exchange syntax as seen in
[@!RFC9110].

An example of a redirect request from a domain registry to a domain registrar, where the registry
implements [@gtld-rdap-profile]:

```
Client Request:

GET /redirects0_ref/related/domain/example.com HTTP/1.1
Accept: application/rdap+json

Server Response:

HTTP/1.1 307 Temporary Redirect
Location: https://registrar.example/domain/example.com
```

An example of a redirect request for a parent IPv4 network:

```
Client Request:

GET /redirects0_ref/rdap-up/ip/192.0.2.42 HTTP/1.1
Accept: application/rdap+json

Server Response:

HTTP/1.1 307 Temporary Redirect
Location: https://rir.example/ip/192.0.2.0/24
```

An example of a redirect request for a parent IPv6 network:

```
Client Request:

GET /redirects0_ref/rdap-up/ip/2001%3adb8%3a%3a1 HTTP/1.1
Accept: application/rdap+json

Server Response:

HTTP/1.1 307 Temporary Redirect
Location: https://rir.example/ip/2001%3adb8%3a%3a/32
```

### Selecting The Appropriate Link

When the server receives a redirect request, it must select which of an object's
links it should use to construct the response.

The `rel` property of the selected link **MUST** match `<relation>` path
segment of the request. The `type` and `hreflang` properties of the link, if
present, **MUST** match the `Accept` and (if specified) `Accept-Language` header
fields of the request.

### Caching by Intermediaries

To facilitate caching of RDAP resources by intermediary proxies, servers which
provide a redirect based on the value of the `Accept` header field in the
request **MUST** include a `Vary` header field (See Section 12.5.5 of
[@!RFC9110]) in the response. This field **MUST** include `accept`, and **MAY**
include other header field names.

Example:

```
Vary: accept, accept-language
```

### Client Processing of Redirect Responses

Note that as per Section 10.2.2 of [@!RFC9110], the URI-reference in `location`
header fields **MAY** be relative. For relative references, RDAP clients
**MUST** compute the full URI using the request URI.

## RDAP Conformance {#rdapConformance}

Servers which implement this extension **MUST** include the string
"`redirects0`" in the "`rdapConformance`" array in responses to RDAP "help"
queries.

## Bootstrap Use Case {#bootstrap}

The primary use case of this extension is a one-hop redirect, where the client is not interested in the use
of this extension beyond the first redirect. Another use case is querying a bootstrap redirect server for
the authoritative source of information according to the IANA RDAP bootstrap information.

```
Client Request:

GET /redirects0_ref/rdap-bootstrap/ip/2001%3adb8%3a%3a1 HTTP/1.1
Accept: application/rdap+json"

Server Response:

HTTP/1.1 307 Temporary Redirect
Location: https://rir1.example/ip/2001%3adb8%3a%3a/32
```

Other uses cases may exist, but for this specific use case, this document registers the "rdap-bootstrap"
link relationship type.

## Multi-Hop Redirect Limitations {#multi_hop}

In some scenarios, a target server might have a policy to issue another redirect using this extension.
For example:

```
Client Request to rdap1.example:

GET /redirects0_ref/rdap-example/exampleFoo_thing/abc HTTP/1.1
Accept: application/rdap+json"

Server Response:

HTTP/1.1 307 Temporary Redirect
Location: https://rdap2.example/redirects0_ref/rdap-example/exampleFoo_thing/abc
```

Note "rdap-example" is not a real relationship and is provided only for demostration purposes.

In this scenario rdap1.example is redirecting to rdap2.example with a "/redirects0_ref" path. However,
not all servers may support this extension. Therefore, the "/redirects0_ref" path defined in this
specification **MUST** only be used in an HTTP redirect if the server issuing the redirect is assured that the
target server of the redirect supports this extension.

# noRedirects0 RDAP Extension

## Usage of noRedirects0

A client can signal to a server, using the method specified in [@!I-D.ietf-regext-rdap-x-media-type],
the preference to not receive a redirect using the `noRedirect0` extension
identifier. Because there is no guarantee that a server can honor this signal,
a client MUST be capable of processing a redirect if this signal is sent.

If a server honors the `noRedirects0` extension and does not issue a redirect,
the server MUST respond with an RDAP resource as identified by the media type
specified in [@!RFC7480] (i.e., the response cannot be a web page or some other
resource that is not parsable as RDAP JSON).

The following example demonstrates the `noRedirects0` extension in the lookup of an IP address.

```
Client Request:

GET /ip/192.0.2.42 HTTP/1.1
Accept: application/rdap+json;exts_list=rdap_level_0+noRedirects0

Server Response:

HTTP/1.1 200 OK
Content-Type: application/rdap+json

{ "rdapConformance" : [ "rdap_level_0", "noRedirects0" ],
  "objectClassName": "ip network",
  "ipVersion": "v4",
  "handle": "NET-EXAMPLE",
  "startAddress": "192.0.2.0",
  "endAddress": "192.0.2.255",
  "notices" : [
    { "description" : [ "Data from RFC9224 origin" ] } ]
}

```

## RDAP Conformance {#rdapConformance}

Servers which implement this extension **MUST** include the string
"`noRedirects0`" in the "`rdapConformance`" array in responses to RDAP "help"
queries.

# IANA Considerations

## redirects0 RDAP Extension Identifier

IANA is requested to register the following value in the [@rdap-extensions]
Registry:

**Extension identifier:** `redirects0`

**Registry operator:** any.

**Published specification:** this document.

**Contact:** the authors of this document.

**Intended usage:** this extension allows clients to request to be redirected to a
related resource for an RDAP resource.

## noRedirects0 RDAP Extension Identifier

IANA is requested to register the following value in the [@rdap-extensions]
Registry:

**Extension identifier:** `noRedirects0`

**Registry operator:** any.

**Published specification:** this document.

**Contact:** the authors of this document.

**Intended usage:** this extension allows clients to signal a preference not to be redirected to a resource.

## Link Relations {#linkrelation}

IANA is requested to register the following value into the [@link-relations] registry.

### rdap-bootstrap

**Relation Name:** rdap-bootstrap

**Description:** Refers to an RDAP object for which a reference can be derived from RFC 9224.

**Reference:** This document once published as an RFC.

### rdap-related-top

**Relation Name:** rdap-related-top

**Description:** Refers to an RDAP resource related to another RDAP resource at the top of a hierarchy, such as a hierarchy described in [@!RFC9910].

**Reference:** This document once published as an RFC.

### rdap-related-bottom

**Relation Name:** rdap-related-bottom

**Description:** Refers to an RDAP resource related to another RDAP resource at the bottom of a hierarchy, such as a hierarchy described in [@!RFC9910].

**Reference:** This document once published as an RFC.

### rdap-related-up

**Relation Name:** rdap-related-up

**Description:** Refers to an RDAP resource related to another RDAP resource one level up in a hierarchy, such as a hierarchy described in [@!RFC9910].

**Reference:** This document once published as an RFC.

### rdap-related-down

**Relation Name:** rdap-related-down

**Description:** Refers to an RDAP resource related to another RDAP resource one level down in a hierarchy, such as a hierarchy described in [@!RFC9910].

**Reference:** This document once published as an RFC.

## RDAP JSON Values {#rdapjsonvalues}

IANA is requested to register the following value into the [@rdap-json-values] registry:

**Value:** redirect not available

**Type:** notice and remark type

**Description:** No redirect of the requested type is available for this resource.

**Registrant Name:** IESG

**Registrant Contact Information:** iesg@ietf.org

# Security Considerations

A malicious HTTP redirect has the potential to create an infinite loop, which
can exhaust resources on both client and server side.

To prevent such loops, RDAP servers which receive redirect requests for the
`self` relation **MUST** respond with a 400 HTTP status.

As described in Section 15.4 of [@!RFC9110], when processing server responses,
RDAP clients **SHOULD** detect and intervene in cyclical redirections.

# Operational Considerations

The benefits of this extension will not materialize if a client issues a query using
this extension, receives an error, and subsequently requeries a server without using
this extension. Therefore, clients **SHOULD NOT** use this extension unless the client
has _a priori_ knowledge of the target server's ability to process queries with this extension
(because, for example, the server is a member of a class of servers which implement a common "profile").

Likewise, servers **SHOULD NOT** issue redirects in the manner described in (#multi_hop) unless
the origin server has _a priori_ knowledge of the target server's ability to process queries
with this extension.

A redirect loop will occur if a server issues a redirect causing a client to follow
redirects back to a previous server queried during the processing of the same query.
Clients **MUST** cancel any queries when a redirect loop is detected. Servers **MUST NOT**
issue responses that cause redirect loops.

# Change Log

This section is to be removed before publishing as an RFC.

## Changes from 04 to 05

* Switch back to 400 as the status for redirects for search and help requests, and provide an example response with a new notice type.
* Define new link relations and explain them in the Abstract.
* Updated Security Considerations as per WG feedback.
* Added Geofeed example (thanks Jasdip).

## Changes from 03 to 04

* Fixed some broken references.

* Updated [@introduction] as clients will know whether or not the server supports this extension.

* Added [@ack].

## Changes from 02 to 03

* Consistely refer to "redirect" instead of "referral". This includes changing
  the extension identifier to `redirects0` and the document title.

* Added (#bootstrap) and (#linkrelation).

* Correct specification of the redirect query path.

* Updated (#rdapConformance) to limit the use of the extension identifier to
  help responses.

* Include 308 in the list of redirection HTTP status codes.

Thanks to Jasdip Singh for identifying the last three of these issues.

## Changes from 01 to 02

* Add reference to [@gtld-rdap-profile] which describes how gTLD RDAP servers
  link to registrar RDAP resoures.

* Include `<base path>` in the path specification, and remove the `/` between
  `<relation>` and `<lookup path>` so that naive URL construction works.

* Reuse the language from RFC 7480 on HTTP status codes used for redirection.

* Fix HTTP status code in the examples.

* Described the risk of redirection loops and things clients and servers have to
  do.

## Changes from 00 to 01

* Switch to using a path segment and a 30x redirect.

* Describe how the server behaves when multiple links exist.

## Changes from draft-brown-rdap-referrals-02 to draft-ietf-regext-rdap-referrals-00

* Nothing apart from the name.

## Changes from 01 to 02

* add this change log.

## Changes from 00 to 01

* change extension identifer from `registrar_link_header` to `redirects0`.

# Acknowledgements {#ack}

The authors would like to thank the following persons for their feedback and advice:

Jasdip Singh, Pawel Kowalik, Tom Harrison, Ben Schwartz.

{backmatter}

<reference anchor="gtld-rdap-profile" target="https://www.icann.org/gtld-rdap-profile">
    <front>
        <title>gTLD RDAP Profile</title>
        <author>
            <organization>ICANN</organization>
        </author>
        <date year="2024"/>
    </front>
</reference>

<reference anchor='link-relations' target='https://www.iana.org/assignments/link-relations/link-relations.xhtml'>
    <front>
        <title>Link Relations</title>
        <author>
            <organization>IANA</organization>
        </author>
    </front>
</reference>

<reference anchor='rdap-extensions' target='https://www.iana.org/assignments/rdap-extensions/rdap-extensions.xhtml'>
    <front>
        <title>RDAP Extensions</title>
        <author>
            <organization>IANA</organization>
        </author>
    </front>
</reference>

<reference anchor='rdap-json-values' target='https://www.iana.org/assignments/rdap-json-values/rdap-json-values.xhtml'>
    <front>
        <title>RDAP JSON Values</title>
        <author>
            <organization>IANA</organization>
        </author>
    </front>
</reference>
