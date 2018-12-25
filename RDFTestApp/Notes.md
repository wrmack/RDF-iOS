#  Notes

Note: the bundle was created with browserify standalone option set to 'RDF'.  All exports in index.js are available to Swift through 'RDF'.

Removed (commented out) requires for Fetcher and UpdateManager to avoid hassles with references to self / window etc (whatwg-fetch refers to self which is defined in a browser but not in this app).  Aim is to use rdflib.js only for managing rdf and do networking natively.

ES6-promise complains it cannot find module 'vertx' but seems to work OK regardless.


