//
//  ViewController.swift
//  RDFTestApp
//
//  Created by Warwick McNaughton on 18/12/18.
//  Copyright © 2018 Warwick McNaughton. All rights reserved.
//

import UIKit
import JavaScriptCore



class ViewController: UIViewController {
    var context = JSContext()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRdfLib()
        testStore()
    }
    
    
    func setupContext() {
        
        // Catch JavaScript exceptions
        context!.exceptionHandler = { context, error in
            print("JS Error: \(error!)")
        }
        
        let nativePrint: @convention(block) (String) -> Void = { message in
            print("JS print: \(message)")
        }
        context!.setObject(nativePrint, forKeyedSubscript: "nativePrint" as NSString)
    }
    
    /*
     Write the bundled javascript RDF library into the javascript context.
     Note: the bundle was created with browserify standalone option set to "RDF".
     All exports in index.js are available to Swift through RDF.
     */
    func setupRdfLib() {
        
        guard let rdfPath = Bundle.main.path(forResource: "rdfbundle", ofType: "js")
            else { print("Unable to read resource files."); return }
        
        do {
            let jsCode = try String(contentsOfFile: rdfPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(jsCode)
        }
        catch {
            print("Evaluate script failed")
        }
    }
    
    
    /*
     Create new RDF object in the javascript context.
     Pass the code to be parsed to the Parser parse function, storing the result in 'result' variable.
     Access the 'result' variable which contains an array of quads.
     Extract subject, predicate and object values from each quad.
     */
    func testStore() {

        context?.evaluateScript("var store = RDF.graph();")
        context?.evaluateScript("var VCARD = new RDF.Namespace('http://www.w3.org/2006/vcard/ns#');")
        
        print("\n==========================\nTesting adding a triple...\n==========================")
        context?.evaluateScript("var me = store.sym('https://wrmack.inrupt.net/profile/card#me');")
        context?.evaluateScript("var profile = me.doc();")
        context?.evaluateScript("store.add(me, VCARD('fn'), 'Warwick McNaughton', profile);")
        print("Triple added was the vcard formatted name 'Warwick McNaughton' for the profile from https://wrmack.inrupt.net/profile/card#me")
        print("Testing finding the name using store.any():")
        context?.evaluateScript("var name = store.any(me, VCARD('fn'), null, profile);")
        let foundName = context?.objectForKeyedSubscript("name")
        print("\nName found in store: \(foundName!)")
        
        context?.evaluateScript("var triples = store.toNT();")
        var storeTriples = context?.objectForKeyedSubscript("triples")
        print("\nTriples now held in the store: \n\(storeTriples!)")
        
        print("\n================================\nTesting adding another triple...\n================================")
        context?.evaluateScript("var bob = store.sym('https://bob.example.com/profile/card#me');")
        context?.evaluateScript("var bobProfile = bob.doc();")
        context?.evaluateScript("store.add(bob, VCARD('fn'), 'Bob', bobProfile);")
         print("Triple added was the vcard formatted name 'Bob' for the profile from https://bob.example.com/profile/card#me")

        context?.evaluateScript("var name2 = store.any(bob, VCARD('fn'), null, bobProfile);")
        let foundName2 = context?.objectForKeyedSubscript("name2")
        print("\nName found in store: \(foundName2!)")
        
        context?.evaluateScript("triples = store.toNT();")
        storeTriples = context?.objectForKeyedSubscript("triples")
        print("\nTriples now held in the store: \n\(storeTriples!)")
        
        print("\n=======================================\nTesting adding a triple using turtle...\n=======================================")
        context?.evaluateScript("var text = '<#this>  a  <#Example> .';")
        context?.evaluateScript("let doc = RDF.sym('https://example.com/alice/card');")
        context?.evaluateScript("RDF.parse(text, store, doc.uri, 'text/turtle'); ")
        context?.evaluateScript("triples = store.toNT();")
        storeTriples = context?.objectForKeyedSubscript("triples")
        print("Triple added was parsed from '<#this>  a  <#Example> .'")
        
        print("\nTriples now held in the store: \n\(storeTriples!)")
        
        print("\n====================================\nTesting converting back to turtle...\n====================================")
        context?.evaluateScript("var turtle = RDF.serialize(doc,store, doc.uri, 'text/turtle');")
        let turtle = context?.objectForKeyedSubscript("turtle")
        print("\n\(turtle!)")
        
        
        let jsStore = context?.objectForKeyedSubscript("store")
        let store = jsStore?.toDictionary() as! [String : Any]
        
        
        print("\n=======================\nInvestigating the store...\n=======================")
        print("\nAll keys in store:")
        print(store.keys)
        print("\nTriples are held in statements.  Printing values for the 'statements' key:")
        print(store["statements"]!)
        
        print("\n==================================\nTesting fetching data using url...\n==================================")
        
        let cardURL = URL(string: "https://www.w3.org/People/Berners-Lee/card#i")
        //        let cardURL = URL(string: "https://ruben.verborgh.org/profile/#me")
        //        let cardURL = URL(string: "https://wrmack.inrupt.net/profile/card#me")
        print("Url: \(cardURL!)")
        
        fetch(url: cardURL!, callback: { response, mimetype in
            print("\nReturned data: \n================ \n")
            print("Mime-type: \(mimetype)")
            print("Data: \n\(response)")

            self.context?.evaluateScript("RDF.parse(`" + response + "`, store, 'https://ruben.verborgh.org/profile/#me', 'text/turtle')")
            self.context?.evaluateScript("triples = store.toNT();")
            storeTriples = self.context?.objectForKeyedSubscript("triples")
            print("\n==============================\nTriples now held in the store:\n==============================\n\(storeTriples!)")
        })

    }
    
    
    /*
     Helper method
     Url fetcher with callback
     */
    func fetch(url: URL, callback: @escaping (String, String) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            print("\nResponse:\n\(response! as Any)")
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    print((response as? HTTPURLResponse)?.allHeaderFields as! [String : Any] )
                    return
            }
            print("\nAll headers:\n\(httpResponse.allHeaderFields as! [String : Any])")

            let string = String(data: data!, encoding: .utf8)
            callback(string!, httpResponse.mimeType!)
        }
        task.resume()
    }
}


