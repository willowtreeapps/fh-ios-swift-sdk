/*
 * JBoss, Home of Professional Open Source.
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}

/**
 This class provides the layer to do http request.
 */
public class InitRequest: Request {
    var config: Config
    /// Properties returned once FH.init succeeds. Those properties are persisted on the device.
    public var props: CloudProps?
    let path: String
    let args: [String: Any]?
    let headers: [String: String]?
    let method: HTTPMethod

    /**
     Constructor.

     - parameter config: contains the setting available in `fhconfig.plist`, populated by customer or by RHMAP platform at project creation.
     */
    public init(config: Config) {
        self.path = "/box/srv/1.1/app/init"
        let defaultParameters: [String: Any]? = config.params
        self.args = defaultParameters
        self.headers = nil
        self.method = .POST
        self.props = nil
        self.config = config
    }

    /**
     Execute method of this command pattern class. It actually does the call to the server.

     - parameter completionHandler: closure that runs once the call is completed. To check error parameter.

        When passed the following config:

        {
            "cuid": "F04E3F31427745EDB06D7E7EC72E2D36",
            "cuidMap": null,
            "destination": "web",
            "sdk_version": "FH_JS_SDK/3.0.2",
            "appid": "random-app-id",
            "appkey": "random-app-key",
            "projectid": "random-proj-id",
            "connectiontag": "0.0.8",
        }

        This is what FeedHenry returned:
        {
            "apptitle": "Some IOS App",
            "domain": "somedom",
            "firstTime": true,
            "hosts": {
                "environment": "envstr",
                "type": "cloud_nodejs",
                "url": "https://somedom-random-enenvstrv.mbaas1.qea.feedhenry.com"
            },
            "init": {
                "trackId": "random-track-24-lc-alpha-num"
            },
            "status": "ok"
        }

     */
    public func exec(completionHandler: @escaping CompletionBlock) -> Void {
        assert(config["host"] != nil, "Property file fhconfig.plist must have 'host' defined.")

        let host = config["host"]!
        let env: String? = config["env"]
        let title: String? = config["title"]
        let domain: String? = config["domain"]

        // let's pretend the former init cloud call actually happened
        // wasted a lot of time looking for what the trackId is used for in the Cloud
        // never found a reason for it so generating a random one
        let hostsObj: [String: AnyObject] = [
            "environment": env as AnyObject,
            "type": "cloud_nodejs" as AnyObject,
            "url": host as AnyObject
        ]
        let initObj: [String: AnyObject] = [
            "trackId": randomString(length: 24) as AnyObject
        ]
        let respJSON: [String: AnyObject] = [
            "apptitle": title as AnyObject,
            "domain": domain as AnyObject,
            "firstTime": true as AnyObject,
            "hosts": hostsObj as AnyObject,
            "init": initObj as AnyObject,
            "status": "ok" as AnyObject
        ]

        self.props = CloudProps(props: respJSON)
        UserDefaults.standard.set(respJSON, forKey: "hosts")

        let fhResponse = Response()
        fhResponse.responseStatusCode = 200
        fhResponse.parsedResponse = respJSON as NSDictionary
        fhResponse.error = nil

        if let data = try? JSONSerialization.data(withJSONObject: respJSON, options: .prettyPrinted) {
            fhResponse.rawResponseAsString = String(data: data, encoding: String.Encoding.utf8)
            fhResponse.rawResponse = data
        }

        completionHandler(fhResponse, nil)

    }
}
