# RDF-iOS
Using the rdflib.js library in iOS with the Javascriptcore api

This might assist others trying to integrate rdf and Solid into iOS.

I installed the rdflib.js library from https://github.com/linkeddata/rdflib.js  (using npm).

Then bundled the library with browserify in standalone mode:

```
browserify src/index.js --standalone RDF  > rdfbundle.js
```

Standalone mode gives you access to all exports in index.js from Swift.

All the app does is run through a few tests and print these out to the Xcode console.
